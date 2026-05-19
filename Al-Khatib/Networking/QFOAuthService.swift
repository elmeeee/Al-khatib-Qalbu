//
//  QFOAuthService.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import AuthenticationServices
import CryptoKit
import Foundation
import OSLog
internal import UIKit

private let oauthLog = Logger(subsystem: "co.kamy.Al-Khatib", category: "OAuth")

private func oauthConsole(_ message: String) {
    print("[AL-Khatib] \(message)")
}

enum QFOAuthError: LocalizedError {
    case invalidRedirectURI
    case invalidAuthorizeURL
    case missingAuthorizationCode
    case stateMismatch
    case nonceMismatch
    case missingRefreshToken
    case tokenExchangeFailed(String)
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .invalidRedirectURI:
            return "Invalid OAuth redirect URI."
        case .invalidAuthorizeURL:
            return "Could not build OAuth authorize URL."
        case .missingAuthorizationCode:
            return "Missing authorization code from callback."
        case .stateMismatch:
            return "Security check failed (state mismatch)."
        case .nonceMismatch:
            return "Security check failed (nonce mismatch)."
        case .missingRefreshToken:
            return "Missing refresh token."
        case .tokenExchangeFailed(let message):
            return "Token exchange failed: \(message)"
        case .userCancelled:
            return "Sign-in cancelled."
        }
    }
}

@MainActor
final class QFOAuthService: NSObject, ASWebAuthenticationPresentationContextProviding {
    private enum OAuthGrantType {
        case authorizationCode(code: String, verifier: String)
        case refreshToken(String)
    }

    private struct PendingAuth: Codable {
        let verifier: String
        let state: String
        let nonce: String
    }

    private let configuration: QFConfiguration
    private let userSession: QFUserSession
    private let session: URLSession
    private let defaults = UserDefaults.standard
    private var authSession: ASWebAuthenticationSession?
    private var pendingAuth: PendingAuth?
    private let pendingAuthKey = "qf.oauth.pendingAuth"
    private var isHandlingCallback = false
    private var lastHandledCode: String?

    init(configuration: QFConfiguration, userSession: QFUserSession) {
        self.configuration = configuration
        self.userSession = userSession
        self.session = URLSession.shared
        self.pendingAuth = Self.loadPendingAuth(defaults: defaults, key: pendingAuthKey)
    }

    func signIn() async throws {
        let verifier = Self.randomURLSafe(length: 64)
        let challenge = Self.codeChallenge(from: verifier)
        let state = Self.randomURLSafe(length: 32)
        let nonce = Self.randomURLSafe(length: 32)
        guard let callbackScheme = configuration.oauthAppRedirectURI.scheme else {
            throw QFOAuthError.invalidRedirectURI
        }

        guard var comps = URLComponents(url: configuration.oauthAuthorizeURL, resolvingAgainstBaseURL: false) else {
            throw QFOAuthError.invalidAuthorizeURL
        }
        comps.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "redirect_uri", value: configuration.oauthRedirectURI.absoluteString),
            URLQueryItem(name: "scope", value: configuration.oauthScopes),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "nonce", value: nonce)
        ]
        guard let authorizeURL = comps.url else {
            throw QFOAuthError.invalidAuthorizeURL
        }

        pendingAuth = PendingAuth(verifier: verifier, state: state, nonce: nonce)
        Self.savePendingAuth(pendingAuth, defaults: defaults, key: pendingAuthKey)
        let callbackURL = try await startWebAuth(
            authorizeURL: authorizeURL,
            callbackScheme: callbackScheme
        )
        do {
            try await completeSignIn(from: callbackURL)
        } catch {
            oauthConsole("signIn failed: \(error.localizedDescription)")
            throw error
        }
    }

    func signOut() async {
        await userSession.clear()
    }

    func refreshAccessTokenIfPossible() async throws {
        guard let refresh = await userSession.userRefreshToken(), refresh.isEmpty == false else {
            throw QFOAuthError.missingRefreshToken
        }
        oauthLog.debug("Refreshing access token using stored refresh token, refreshToken length=\(refresh.count, privacy: .public)")
        let refreshed = try await refreshToken(refresh)
        await userSession.setUserTokens(
            accessToken: refreshed.accessToken,
            refreshToken: refreshed.refreshToken ?? refresh
        )
    }

    func introspectCurrentAccessToken(requiredScopes: String? = nil) async throws -> OAuthIntrospectionResponse {
        let accessToken = try await userSession.userAccessToken()
        return try await introspectToken(token: accessToken, requiredScopes: requiredScopes)
    }

    func handleIncomingCallback(_ url: URL) async {
        guard isHandlingCallback == false else {
            return
        }
        guard let pending = pendingAuth ?? Self.loadPendingAuth(defaults: defaults, key: pendingAuthKey) else {
            return
        }
        guard Self.matchesRegisteredRedirect(url, configuration: configuration) else {
            return
        }
        pendingAuth = pending
        do {
            let code = try Self.authorizationCode(from: url, expectedState: pending.state)
            if lastHandledCode == code {
                return
            }
            isHandlingCallback = true
            defer { isHandlingCallback = false }
            lastHandledCode = code
            try await completeSignIn(from: url)
        } catch {
            oauthLog.error("Callback handling failed: \(error.localizedDescription, privacy: .public)")
            oauthConsole("handleIncomingCallback failed: \(error.localizedDescription)")
        }
    }

    private func startWebAuth(authorizeURL: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            var didResume = false
            let session = ASWebAuthenticationSession(
                url: authorizeURL,
                callbackURLScheme: callbackScheme
            ) { url, error in
                if didResume {
                    return
                }
                if let url {
                    didResume = true
                    continuation.resume(returning: url)
                    return
                }
                if let err = error as? ASWebAuthenticationSessionError,
                   err.code == .canceledLogin {
                    didResume = true
                    continuation.resume(throwing: QFOAuthError.userCancelled)
                    return
                }
                didResume = true
                continuation.resume(throwing: error ?? QFOAuthError.userCancelled)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            self.authSession = session
            _ = session.start()
        }
    }

    private func completeSignIn(from callbackURL: URL) async throws {
        guard let pending = pendingAuth else {
            throw QFOAuthError.tokenExchangeFailed("Missing PKCE context.")
        }
        let code = try Self.authorizationCode(from: callbackURL, expectedState: pending.state)
        let token = try await exchangeCodeForToken(
            code: code,
            verifier: pending.verifier,
            expectedNonce: pending.nonce
        )
        await userSession.setUserTokens(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken
        )
        _ = await userSession.hasUserAccessToken()
        pendingAuth = nil
        Self.savePendingAuth(nil, defaults: defaults, key: pendingAuthKey)
    }

    private func exchangeCodeForToken(code: String, verifier: String, expectedNonce: String) async throws -> UserTokenResponse {
        do {
            let decoded = try await requestToken(
                grant: .authorizationCode(code: code, verifier: verifier),
                includeAcceptJSON: false
            )
            if let idToken = decoded.idToken {
                let nonce = try Self.nonceClaim(fromIDToken: idToken)
                guard nonce == expectedNonce else {
                    throw QFOAuthError.nonceMismatch
                }
            }
            guard decoded.accessToken.isEmpty == false else {
                throw QFOAuthError.tokenExchangeFailed("missing access_token")
            }
            return decoded
        } catch let qf as QFError {
            throw QFOAuthError.tokenExchangeFailed(qf.localizedDescription)
        } catch {
            throw QFOAuthError.tokenExchangeFailed(error.localizedDescription)
        }
    }

    private func refreshToken(_ refreshToken: String) async throws -> UserTokenResponse {
        try await requestToken(
            grant: .refreshToken(refreshToken),
            includeAcceptJSON: true
        )
    }

    private func requestToken(
        grant: OAuthGrantType,
        includeAcceptJSON: Bool
    ) async throws -> UserTokenResponse {
        let tokenURL = configuration.authBaseURL
            .appendingPathComponent(AppEndpoints.OAuth.directory)
            .appendingPathComponent(AppEndpoints.OAuth.token)
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        if includeAcceptJSON {
            req.setValue("application/json", forHTTPHeaderField: "Accept")
        }
        if let secret = configuration.clientSecret, secret.isEmpty == false {
            let basic = "\(configuration.clientId):\(secret)"
                .data(using: .utf8)?
                .base64EncodedString() ?? ""
            req.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        }
        let body: String
        switch grant {
        case .authorizationCode(let code, let verifier):
            body = [
                "grant_type=authorization_code",
                "client_id=\(Self.percentEncode(configuration.clientId))",
                "code=\(Self.percentEncode(code))",
                "redirect_uri=\(Self.percentEncode(configuration.oauthRedirectURI.absoluteString))",
                "code_verifier=\(Self.percentEncode(verifier))"
            ].joined(separator: "&")
        case .refreshToken(let refreshToken):
            body = [
                "grant_type=refresh_token",
                "client_id=\(Self.percentEncode(configuration.clientId))",
                "refresh_token=\(Self.percentEncode(refreshToken))",
                "redirect_uri=\(Self.percentEncode(configuration.oauthRedirectURI.absoluteString))"
            ].joined(separator: "&")
        }
        req.httpBody = body.data(using: .utf8)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw QFOAuthError.tokenExchangeFailed("non-http response")
        }
        guard (200...299).contains(http.statusCode) else {
            let snippet = String(data: data, encoding: .utf8) ?? ""
            switch grant {
            case .authorizationCode:
                oauthLog.error("Token exchange failed with HTTP status \(http.statusCode, privacy: .public)")
                oauthConsole("token HTTP \(http.statusCode): \(snippet.prefix(500))")
            case .refreshToken:
                oauthConsole("refresh token HTTP \(http.statusCode): \(snippet.prefix(500))")
            }
            throw QFOAuthError.tokenExchangeFailed("http \(http.statusCode) \(snippet)")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(UserTokenResponse.self, from: data)
        switch grant {
        case .authorizationCode:
            oauthLog.debug("authorization_code response refreshTokenPresent=\(decoded.refreshToken != nil, privacy: .public)")
        case .refreshToken:
            oauthLog.debug("refresh_token response refreshTokenPresent=\(decoded.refreshToken != nil, privacy: .public)")
        }
        guard decoded.accessToken.isEmpty == false else {
            switch grant {
            case .authorizationCode:
                throw QFOAuthError.tokenExchangeFailed("missing access_token")
            case .refreshToken:
                throw QFOAuthError.tokenExchangeFailed("missing access_token on refresh")
            }
        }
        return decoded
    }

    private func introspectToken(token: String, requiredScopes: String?) async throws -> OAuthIntrospectionResponse {
        let url = configuration.authBaseURL
            .appendingPathComponent(AppEndpoints.OAuth.directory)
            .appendingPathComponent(AppEndpoints.OAuth.introspect)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let secret = configuration.clientSecret, secret.isEmpty == false {
            let basic = "\(configuration.clientId):\(secret)"
                .data(using: .utf8)?
                .base64EncodedString() ?? ""
            req.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        }
        var parts = [
            "token=\(Self.percentEncode(token))"
        ]
        if let requiredScopes, requiredScopes.isEmpty == false {
            parts.append("scope=\(Self.percentEncode(requiredScopes))")
        }
        req.httpBody = parts.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw QFOAuthError.tokenExchangeFailed("introspect non-http response")
        }
        guard (200...299).contains(http.statusCode) else {
            let snippet = String(data: data, encoding: .utf8) ?? ""
            oauthConsole("introspect HTTP \(http.statusCode): \(snippet.prefix(500))")
            throw QFOAuthError.tokenExchangeFailed("introspect http \(http.statusCode)")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(OAuthIntrospectionResponse.self, from: data)
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let keyWindow = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) {
            return keyWindow
        }
        guard let scene = scenes.first else {
            preconditionFailure("No UIWindowScene available for OAuth presentation.")
        }
        return ASPresentationAnchor(windowScene: scene)
    }

    private static func authorizationCode(from callbackURL: URL, expectedState: String) throws -> String {
        let items = queryItemsResolvingFragment(from: callbackURL)
        if let oauthErr = items.first(where: { $0.name == "error" })?.value, oauthErr.isEmpty == false {
            let desc = items.first(where: { $0.name == "error_description" })?.value ?? oauthErr
            let readable = desc.removingPercentEncoding ?? desc
            throw QFOAuthError.tokenExchangeFailed(readable)
        }
        let state = items.first(where: { $0.name == "state" })?.value
        let code = items.first(where: { $0.name == "code" })?.value
        guard state == expectedState else { throw QFOAuthError.stateMismatch }
        guard let code, code.isEmpty == false else { throw QFOAuthError.missingAuthorizationCode }
        return code
    }

    /// Matches either `oauthRedirectURI` or `oauthAppRedirectURI` (scheme/host/path).
    private static func matchesRegisteredRedirect(_ url: URL, configuration: QFConfiguration) -> Bool {
        for expected in [configuration.oauthRedirectURI, configuration.oauthAppRedirectURI] {
            guard let e = URLComponents(url: expected, resolvingAgainstBaseURL: false),
                  let u = URLComponents(url: url, resolvingAgainstBaseURL: false) else { continue }
            if e.scheme?.lowercased() == u.scheme?.lowercased(),
               e.host == u.host,
               e.path == u.path {
                return true
            }
        }
        return false
    }

    private static func queryItemsResolvingFragment(from url: URL) -> [URLQueryItem] {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return [] }
        if let queryItems = comps.queryItems, queryItems.isEmpty == false {
            return queryItems
        }
        guard let fragment = comps.fragment, fragment.contains("=") else { return [] }
        var frag = URLComponents()
        frag.query = fragment
        return frag.queryItems ?? []
    }

    private static func randomURLSafe(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    private static func codeChallenge(from verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    private static func percentEncode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }

    private static func nonceClaim(fromIDToken token: String) throws -> String {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { throw QFOAuthError.tokenExchangeFailed("invalid id_token format") }
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let mod = payload.count % 4
        if mod > 0 {
            payload += String(repeating: "=", count: 4 - mod)
        }
        guard let data = Data(base64Encoded: payload),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let nonce = json["nonce"] as? String,
              nonce.isEmpty == false else {
            throw QFOAuthError.tokenExchangeFailed("missing nonce in id_token")
        }
        return nonce
    }
}

private extension QFOAuthService {
    private static func savePendingAuth(_ pending: PendingAuth?, defaults: UserDefaults, key: String) {
        guard let pending else {
            defaults.removeObject(forKey: key)
            return
        }
        if let data = try? JSONEncoder().encode(pending) {
            defaults.set(data, forKey: key)
        }
    }

    private static func loadPendingAuth(defaults: UserDefaults, key: String) -> PendingAuth? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PendingAuth.self, from: data)
    }
}

private struct UserTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String?
    let expiresIn: Int?
    let idToken: String?
    let scope: String?
}

struct OAuthIntrospectionResponse: Decodable, Sendable {
    let active: Bool
    let scope: String?
    let clientId: String?
    let sub: String?
    let exp: Int?
    let iat: Int?
    let nbf: Int?
    let aud: [String]?
    let iss: String?
    let tokenType: String?
    let tokenUse: String?
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
