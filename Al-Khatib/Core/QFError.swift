//
//  QFError.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum QFError: Error, LocalizedError, Sendable, Equatable {
    case networkError(URLError)
    case authExpired
    /// HTTP 403 from user APIs (e.g. Reflect) — treat like expired session and prompt sign-in.
    case sessionForbidden
    case apiLimitReached(retryAfter: TimeInterval?)
    case parsingError(String)
    case missingUserSession
    case configurationMissing(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let u):
            return u.localizedDescription
        case .authExpired:
            return "http 401"
        case .sessionForbidden:
            return "http 403"
        case .apiLimitReached:
            return "http 429"
        case .parsingError(let detail):
            return detail
        case .missingUserSession:
            return "missing_user_session"
        case .configurationMissing(let key):
            return key
        }
    }
}

enum QFHTTPStatus {
    static let unauthorized = 401
    static let forbidden = 403
    static let tooManyRequests = 429
}
