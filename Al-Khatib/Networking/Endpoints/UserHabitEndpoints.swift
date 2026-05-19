//
//  UserHabitEndpoints.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum UserHabitGetEndpoint: QFEndpoint {
    case streaksUser(query: [URLQueryItem])
    case currentStreakUser(query: [URLQueryItem], headers: [String: String])
    case activityDaysUser(query: [URLQueryItem], headers: [String: String])

    var route: QFApiClient.RequestRoute {
        switch self {
        case .streaksUser, .currentStreakUser, .activityDaysUser:
            return .authV1User
        }
    }

    var method: QFHTTPMethod { .get }

    var path: String {
        switch self {
        case .streaksUser:
            return AppEndpoints.AuthV1.streaks
        case .currentStreakUser:
            return AppEndpoints.AuthV1.currentStreakDays
        case .activityDaysUser:
            return AppEndpoints.AuthV1.activityDays
        }
    }

    var query: [URLQueryItem] {
        switch self {
        case .streaksUser(let query),
             .currentStreakUser(let query, _),
             .activityDaysUser(let query, _):
            return query
        }
    }

    var headers: [String: String] {
        switch self {
        case .currentStreakUser(_, let headers),
             .activityDaysUser(_, let headers):
            return headers
        case .streaksUser:
            return [:]
        }
    }

    var bodyData: Data? { nil }
}

struct UserHabitPostActivityDaysEndpoint: QFEndpoint {
    let payload: Data
    let headers: [String: String]

    var route: QFApiClient.RequestRoute { .authV1User }
    var method: QFHTTPMethod { .post }
    var path: String { AppEndpoints.AuthV1.activityDays }
    var bodyData: Data? { payload }

    init(bodyData: Data, headers: [String: String]) {
        self.payload = bodyData
        self.headers = headers
    }
}
