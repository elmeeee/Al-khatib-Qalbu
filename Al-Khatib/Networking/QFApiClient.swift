//
//  QFApiClient.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//


import Foundation
import OSLog

private let oauthLog = Logger(subsystem: "co.kamy.Al-Khatib", category: "OAuth.Refresh")

final class QFApiClient: Sendable {
    private static let networkingSession = URLSession.shared

    enum RequestRoute {
        case content
        case user
        case authV1User
        case authV1Client
    }

    private enum AuthContext {
        case contentToken
        case userToken
    }

    private enum RetryContext {
        case contentToken
        case userToken
    }

    private let configuration: QFConfiguration
    private let auth: QFAuthManager
    private let userSession: QFUserSession
    private let session: URLSession
    private let refreshManager: QFRefreshTokenManager

    init(configuration: QFConfiguration, auth: QFAuthManager, userSession: QFUserSession) {
        self.configuration = configuration
        self.auth = auth
        self.userSession = userSession
        self.session = Self.networkingSession
        self.refreshManager = QFRefreshTokenManager()
    }

    private nonisolated static let contentRequestTimeout: TimeInterval = 20
    private nonisolated static let userRequestTimeout: TimeInterval = 30

    func send<T: Decodable & Sendable, E: QFEndpoint>(_ endpoint: E) async throws -> T {
        let route = routeConfig(for: endpoint.route)
        return try await performJSONRequest(
            method: endpoint.method.rawValue,
            base: route.base,
            prefix: route.prefix,
            path: endpoint.path,
            query: endpoint.query,
            authContext: route.auth,
            retryContext: route.retry,
            extraHeaders: endpoint.headers,
            bodyData: endpoint.bodyData,
            idempotencyKey: endpoint.idempotencyKey
        )
    }

    private func routeConfig(for route: RequestRoute) -> (base: URL, prefix: String?, auth: AuthContext, retry: RetryContext) {
        switch route {
        case .content:
            return (configuration.contentAPIBaseURL, AppEndpoints.Prefix.contentAPI, .contentToken, .contentToken)
        case .user:
            return (configuration.userAPIBaseURL, AppEndpoints.Prefix.quranReflect, .userToken, .userToken)
        case .authV1User:
            return (configuration.userAPIBaseURL, AppEndpoints.Prefix.authV1, .userToken, .userToken)
        case .authV1Client:
            return (configuration.userAPIBaseURL, AppEndpoints.Prefix.authV1, .contentToken, .contentToken)
        }
    }

    private func performJSONRequest<T: Decodable & Sendable>(
        method: String,
        base: URL,
        prefix: String?,
        path: String,
        query: [URLQueryItem],
        authContext: AuthContext,
        retryContext: RetryContext,
        extraHeaders: [String: String] = [:],
        bodyData: Data? = nil,
        idempotencyKey: String? = nil
    ) async throws -> T {
        let work = {
            let token = try await self.token(for: authContext)
            let url = self.makeURL(base: base, prefix: prefix, path: path, query: query)
            var req = URLRequest(url: url)
            req.httpMethod = method
            req.timeoutInterval = Self.timeoutInterval(for: retryContext)
            req.cachePolicy = .reloadIgnoringLocalCacheData
            QFHeadersManager.apply(
                to: &req,
                token: token,
                clientId: self.configuration.clientId,
                extraHeaders: extraHeaders
            )
            if let idempotencyKey {
                req.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
            }
            if let bodyData, bodyData.isEmpty == false {
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.httpBody = bodyData
                req.setValue(String(bodyData.count), forHTTPHeaderField: "Content-Length")
            }
            return try await self.session.decodeResponse(T.self, request: req)
        }

        switch retryContext {
        case .contentToken:
            return try await with401Retry(work)
        case .userToken:
            return try await withUser401RefreshRetry(work)
        }
    }

    private func token(for context: AuthContext) async throws -> String {
        switch context {
        case .contentToken:
            return try await auth.accessToken()
        case .userToken:
            return try await userSession.userAccessToken()
        }
    }

    private func makeURL(
        base: URL,
        prefix: String?,
        path: String,
        query: [URLQueryItem]
    ) -> URL {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var url = base
        if let prefix {
            url = url.appending(path: prefix).appending(path: trimmed)
        } else {
            url = url.appending(path: mcpRelativePath(trimmed))
        }
        if query.isEmpty == false,
           var c = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            c.queryItems = query
            url = c.url ?? url
        }
        return url
    }

    private func mcpRelativePath(_ path: String) -> String {
        var p = path
        if p.hasPrefix("/") { p.removeFirst() }
        return p
    }

    private func with401Retry<T: Sendable>(
        _ work: () async throws -> T
    ) async throws -> T {
        do {
            return try await work()
        } catch QFError.authExpired {
            await auth.clearCache()
            return try await work()
        }
    }

    private func withUser401RefreshRetry<T: Sendable>(
        _ work: () async throws -> T
    ) async throws -> T {
        do {
            return try await work()
        } catch QFError.authExpired {
            do {
                try await refreshManager.refreshIfNeeded {
                    try await self.refreshUserAccessToken()
                }
            } catch {
                if isRefreshTokenInvalid(error) {
                    await userSession.clear()
                    throw QFError.missingUserSession
                }
                throw error
            }
            return try await work()
        }
    }

    private func refreshUserAccessToken() async throws {
        guard let refresh = await userSession.userRefreshToken(), refresh.isEmpty == false else {
            throw QFError.missingUserSession
        }
        let tokenURL = configuration.authBaseURL
            .appendingPathComponent(AppEndpoints.OAuth.directory)
            .appendingPathComponent(AppEndpoints.OAuth.token)
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.timeoutInterval = Self.userRequestTimeout
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let secret = configuration.clientSecret, secret.isEmpty == false {
            let basic = "\(configuration.clientId):\(secret)"
                .data(using: .utf8)?
                .base64EncodedString() ?? ""
            req.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        }
        // OAuth 2.0 RFC 6749 §6 — only required fields. "redirect_uri" is NOT required
        // and some servers reject requests that include it for refresh_token grants.
        let body = [
            "grant_type=refresh_token",
            "client_id=\(percentEncode(configuration.clientId))",
            "refresh_token=\(percentEncode(refresh))"
        ].joined(separator: "&")
        req.httpBody = body.data(using: .utf8)

        let (data, response) = try await session.data(for: req)
        try validateHTTP(response, data: data, expectedMinStatus: 200, expectedMaxStatus: 299)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Some servers return {"error": "invalid_grant"} as HTTP 400 instead of 401.
        // Check before assuming the decode succeeds.
        if let text = String(data: data, encoding: .utf8),
           text.contains("\"error\"") {
            let lower = text.lowercased()
            if lower.contains("invalid_grant") || lower.contains("invalid_token") {
                oauthLog.error("Refresh token rejected by server: invalid_grant — clearing session")
                await userSession.clear()
                throw QFError.missingUserSession
            }
        }

        let decoded = try decoder.decode(UserRefreshTokenResponse.self, from: data)
        guard decoded.accessToken.isEmpty == false else {
            throw QFError.parsingError("refresh access_token missing")
        }
        // Persist the new refresh token if the server rotated it (standard practice).
        if let newRefresh = decoded.refreshToken, newRefresh.isEmpty == false {
            oauthLog.debug("Refresh token rotated — persisting new token")
        }
        await userSession.setUserTokens(
            accessToken: decoded.accessToken,
            refreshToken: decoded.refreshToken ?? refresh
        )
    }

    private nonisolated static func timeoutInterval(for retry: RetryContext) -> TimeInterval {
        switch retry {
        case .contentToken:
            return contentRequestTimeout
        case .userToken:
            return userRequestTimeout
        }
    }

    private func percentEncode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }

    private func isRefreshTokenInvalid(_ error: Error) -> Bool {
        let text = (error as? LocalizedError)?.errorDescription?.lowercased()
            ?? error.localizedDescription.lowercased()
        return text.contains("invalid_grant")
            || text.contains("invalid token")
            || text.contains("invalid_token")
    }
}

private struct UserRefreshTokenResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String?
}

private extension URLSession {
    nonisolated static func decodePayload<T: Decodable & Sendable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    func decodeResponse<T: Decodable & Sendable>(_ type: T.Type, request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await self.data(for: request)
            try validateHTTP(response, data: data, expectedMinStatus: 200, expectedMaxStatus: 299)
            do {
                return try Self.decodePayload(T.self, from: data)
            } catch {
                throw QFError.parsingError("decode \(T.self): \(error.localizedDescription)")
            }
        } catch let e as QFError {
            throw e
        } catch let u as URLError {
            throw QFError.networkError(u)
        } catch {
            throw QFError.networkError(URLError(.unknown))
        }
    }
}
