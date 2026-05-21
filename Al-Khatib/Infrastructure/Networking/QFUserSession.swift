//
//  QFUserSession.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import OSLog

private let userSessionLog = Logger(subsystem: "co.kamy.Al-Khatib", category: "UserSession")

actor QFUserSession {
    private enum TokenKind {
        case access
        case refresh
    }

    private let environment: AppEnvironment
    private let keychain = KeychainService()
    private let defaults = UserDefaults.standard
    private var inMemory: String?
    private var inMemoryRefresh: String?

    init(environment: AppEnvironment = .current) {
        self.environment = environment
    }

    private var defaultsKey: String {
        "qf.userAccessToken.\(environment.rawValue.lowercased())"
    }

    private var refreshDefaultsKey: String {
        "qf.userRefreshToken.\(environment.rawValue.lowercased())"
    }

    func setUserAccessToken(_ token: String) async {
        await setUserTokens(accessToken: token, refreshToken: nil)
    }

    func setUserTokens(accessToken: String, refreshToken: String?) async {
        persistToken(accessToken, kind: .access)
        if let refreshToken, refreshToken.isEmpty == false {
            persistToken(refreshToken, kind: .refresh)
        }
        notifySessionDidChange()
    }

    func clear() async {
        inMemory = nil
        inMemoryRefresh = nil
        for env in AppEnvironment.allCases {
            let suffix = env.rawValue.lowercased()
            defaults.removeObject(forKey: "qf.userAccessToken.\(suffix)")
            defaults.removeObject(forKey: "qf.userRefreshToken.\(suffix)")
        }
        keychain.clearUserOAuthTokens()
        notifySessionDidChange()
    }

    private nonisolated func notifySessionDidChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .qfUserSessionDidChange, object: nil)
        }
    }

    func userAccessToken() async throws -> String {
        if let token = loadToken(kind: .access) {
            return token
        }
        userSessionLog.error("Missing user token in memory, keychain, defaults, and process env")
        throw QFError.missingUserSession
    }

    func hasUserAccessToken() async -> Bool {
        loadToken(kind: .access) != nil
    }

    func userRefreshToken() async -> String? {
        loadToken(kind: .refresh)
    }

    private func persistToken(_ token: String, kind: TokenKind) {
        switch kind {
        case .access:
            inMemory = token
            defaults.set(token, forKey: defaultsKey)
        case .refresh:
            inMemoryRefresh = token
            defaults.set(token, forKey: refreshDefaultsKey)
        }
        do {
            try keychain.setString(token, for: keychainKey(for: kind), environment: environment)
            userSessionLog.debug("Stored \(self.tokenName(kind), privacy: .public) token in keychain for env=\(self.environment.rawValue, privacy: .public), length=\(token.count, privacy: .public)")
        } catch {
            userSessionLog.error("Failed storing \(self.tokenName(kind), privacy: .public) token: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadToken(kind: TokenKind) -> String? {
        if let token = inMemoryToken(for: kind), token.isEmpty == false {
            return token
        }
        if let token = try? keychain.getString(for: keychainKey(for: kind), environment: environment), token.isEmpty == false {
            setInMemoryToken(token, for: kind)
            return token
        }
        if let token = defaults.string(forKey: defaultsKey(for: kind)), token.isEmpty == false {
            setInMemoryToken(token, for: kind)
            return token
        }
        if let token = ProcessInfo.processInfo.environment[processEnvKey(for: kind)], token.isEmpty == false {
            return token
        }
        return nil
    }

    private func inMemoryToken(for kind: TokenKind) -> String? {
        switch kind {
        case .access: return inMemory
        case .refresh: return inMemoryRefresh
        }
    }

    private func setInMemoryToken(_ token: String, for kind: TokenKind) {
        switch kind {
        case .access:
            inMemory = token
        case .refresh:
            inMemoryRefresh = token
        }
    }

    private func defaultsKey(for kind: TokenKind) -> String {
        switch kind {
        case .access: return defaultsKey
        case .refresh: return refreshDefaultsKey
        }
    }

    private func processEnvKey(for kind: TokenKind) -> String {
        switch kind {
        case .access: return "QF_USER_ACCESS_TOKEN"
        case .refresh: return "QF_USER_REFRESH_TOKEN"
        }
    }

    private func keychainKey(for kind: TokenKind) -> KeychainService.Key {
        switch kind {
        case .access: return .userAccessToken
        case .refresh: return .userRefreshToken
        }
    }

    private func tokenName(_ kind: TokenKind) -> String {
        switch kind {
        case .access: return "user access"
        case .refresh: return "user refresh"
        }
    }
}

extension Notification.Name {
    static let qfUserSessionDidChange = Notification.Name("qfUserSessionDidChange")
    static let qfOAuthWebAuthStateDidChange = Notification.Name("qfOAuthWebAuthStateDidChange")
    static let qfUserProfileDidUpdate = Notification.Name("qfUserProfileDidUpdate")
}
