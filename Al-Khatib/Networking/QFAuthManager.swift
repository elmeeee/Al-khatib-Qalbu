//
//  QFAuthManager.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

private struct ContentTokenCache: Sendable {
    var value: String
    var expiresAt: Date
    func isValid(now: Date = .now, skew: TimeInterval = 60) -> Bool {
        value.isEmpty == false && now < expiresAt.addingTimeInterval(-skew)
    }
}

actor QFAuthManager {
    private let configuration: QFConfiguration
    private let environment: AppEnvironment
    private let keychain = KeychainService()
    private let session: URLSession

    private var cache: ContentTokenCache?
    private var refreshInFlight: Task<String, Error>?

    init(configuration: QFConfiguration, environment: AppEnvironment = .current) {
        self.configuration = configuration
        self.environment = environment
        self.session = URLSession.shared
    }
    
    func setClientSecret(_ secret: String) throws {
        try keychain.setString(secret, for: .qfClientSecret, environment: environment)
    }

    private func readClientId() -> String {
        return configuration.clientId
    }

    private func readClientSecret() throws -> String {
        if let s = try keychain.getString(for: .qfClientSecret, environment: environment), s.isEmpty == false { return s }
        if let s = configuration.clientSecret, s.isEmpty == false { return s }
        if let s = ProcessInfo.processInfo.environment["QF_CLIENT_SECRET"], s.isEmpty == false { return s }
        throw QFError.configurationMissing("QF_CLIENT_SECRET. Set it in Settings > Authentication > Advanced or edit QFCompiledCredentials in Configuration.swift.")
    }

    func accessToken() async throws -> String {
        let now = Date()
        if let c = cache, c.isValid(now: now) { return c.value }
        if let persisted = try? keychain.getString(for: .contentAccessToken, environment: environment),
           let persistedCache = parsePersistedToken(persisted),
           persistedCache.isValid(now: now) {
            cache = persistedCache
            return persistedCache.value
        }

        if let t = refreshInFlight {
            return try await t.value
        }
        let task = Task { try await self.requestNewClientCredentials() }
        refreshInFlight = task
        defer { refreshInFlight = nil }
        let t = try await task.value
        return t
    }

    func clearCache() {
        cache = nil
        try? keychain.setString("", for: .contentAccessToken, environment: environment)
    }

    func hasClientSecretConfigured() -> Bool {
        if let s = try? keychain.getString(for: .qfClientSecret, environment: environment), s.isEmpty == false {
            return true
        }
        if let s = configuration.clientSecret, s.isEmpty == false { return true }
        if let s = ProcessInfo.processInfo.environment["QF_CLIENT_SECRET"], s.isEmpty == false { return true }
        return false
    }

    private func requestNewClientCredentials() async throws -> String {
        let clientId = readClientId()
        let clientSecret = try readClientSecret()

        let tokenURL = configuration.authBaseURL
            .appendingPathComponent("oauth2")
            .appendingPathComponent("token")
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        let basic = "\(clientId):\(clientSecret)"
            .data(using: .utf8)!
            .base64EncodedString()
        request.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "grant_type=client_credentials&scope=content"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response, data: data, expectedMinStatus: 200, expectedMaxStatus: 299)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded: TokenResponse
        do {
            decoded = try decoder.decode(TokenResponse.self, from: data)
        } catch {
            throw QFError.parsingError("token payload decode failed")
        }
        let expires = Date().addingTimeInterval(TimeInterval(max(decoded.expiresIn - 60, 0)))
        cache = .init(value: decoded.accessToken, expiresAt: expires)
        let persisted = "\(decoded.accessToken)|\(expires.timeIntervalSince1970)"
        try? keychain.setString(persisted, for: .contentAccessToken, environment: environment)
        return decoded.accessToken
    }

    private func parsePersistedToken(_ value: String) -> ContentTokenCache? {
        let parts = value.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let epoch = TimeInterval(parts[1]) else {
            return nil
        }
        return .init(value: parts[0], expiresAt: Date(timeIntervalSince1970: epoch))
    }
}

func validateHTTP(_ response: URLResponse, data: Data, expectedMinStatus: Int, expectedMaxStatus: Int) throws {
    guard let http = response as? HTTPURLResponse else {
        throw QFError.parsingError("not http")
    }
    if http.statusCode == QFHTTPStatus.tooManyRequests {
        let retry = http.value(forHTTPHeaderField: "Retry-After")
            .flatMap { Int($0) }
            .map { TimeInterval($0) }
        throw QFError.apiLimitReached(retryAfter: retry)
    }
    if http.statusCode == QFHTTPStatus.unauthorized {
        throw QFError.authExpired
    }
    guard (expectedMinStatus...expectedMaxStatus).contains(http.statusCode) else {
        if let message = extractAPIErrorMessage(from: data), message.isEmpty == false {
            throw QFError.parsingError("http \(http.statusCode) \(message)")
        }
        let snippet = String(data: data, encoding: .utf8) ?? ""
        throw QFError.parsingError("http \(http.statusCode) \(snippet.prefix(200))")
    }
}

private func extractAPIErrorMessage(from data: Data) -> String? {
    guard
        let object = try? JSONSerialization.jsonObject(with: data),
        let root = object as? [String: Any]
    else {
        return nil
    }

    for key in ["message", "error", "detail", "error_description"] {
        if let text = root[key] as? String, text.isEmpty == false {
            return text
        }
    }

    if let errors = root["errors"] as? [Any], errors.isEmpty == false {
        let parts = errors.compactMap { item -> String? in
            if let text = item as? String, text.isEmpty == false { return text }
            if let dict = item as? [String: Any] {
                for key in ["message", "error", "detail"] {
                    if let text = dict[key] as? String, text.isEmpty == false { return text }
                }
            }
            return nil
        }
        if parts.isEmpty == false {
            return parts.joined(separator: ", ")
        }
    }

    if let errorsDict = root["errors"] as? [String: Any], errorsDict.isEmpty == false {
        let parts = errorsDict.compactMap { (_, value) -> String? in
            if let text = value as? String, text.isEmpty == false { return text }
            if let arr = value as? [String], arr.isEmpty == false { return arr.joined(separator: ", ") }
            return nil
        }
        if parts.isEmpty == false {
            return parts.joined(separator: ", ")
        }
    }

    if let details = root["details"] as? [String: Any],
       let error = details["error"] as? [String: Any],
       let nested = error["details"] as? [String: Any] {
        let parts = nested.map { key, value in
            if let text = value as? String { return "\(key): \(text)" }
            return "\(key): \(value)"
        }
        if parts.isEmpty == false {
            let msg = error["message"] as? String ?? "Validation Error"
            return "\(msg) (\(parts.joined(separator: ", ")))"
        }
    }

    return nil
}
