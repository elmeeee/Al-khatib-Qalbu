//
//  KeychainService.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Security

struct KeychainService: Sendable {
    enum Key: String, Sendable {
        case qfClientId
        case qfClientSecret
        case contentAccessToken
        case userAccessToken
        case userRefreshToken
    }

    private let service: String

    nonisolated init(service: String = "co.kamy.Al-Khatib") {
        self.service = service
    }

    private func accountName(for key: Key, environment: AppEnvironment?) -> String {
        guard let environment else { return key.rawValue }
        return "\(key.rawValue).\(environment.rawValue.lowercased())"
    }

    func set(_ data: Data, for key: Key, environment: AppEnvironment? = nil) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountName(for: key, environment: environment)
        ]
        SecItemDelete(query as CFDictionary)

        var newQuery = query
        newQuery[kSecValueData as String] = data
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(newQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw QFError.parsingError("keychain set failed: \(status)")
        }
    }

    func get(for key: Key, environment: AppEnvironment? = nil) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountName(for: key, environment: environment),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw QFError.parsingError("keychain get failed: \(status)")
        }
        return data
    }

    func setString(_ value: String, for key: Key, environment: AppEnvironment? = nil) throws {
        try set(Data(value.utf8), for: key, environment: environment)
    }

    func getString(for key: Key, environment: AppEnvironment? = nil) throws -> String? {
        try get(for: key, environment: environment).flatMap { String(data: $0, encoding: .utf8) }
    }

    func delete(for key: Key, environment: AppEnvironment? = nil) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountName(for: key, environment: environment)
        ]
        SecItemDelete(query as CFDictionary)
    }
}
