//
//  ReflectEndpoints.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum ReflectEndpoint: QFEndpoint {
    case profile
    case activityDays
    case posts

    var route: QFApiClient.RequestRoute { .user }
    var method: QFHTTPMethod { .get }

    var path: String {
        switch self {
        case .profile:
            return AppEndpoints.Reflect.userProfile
        case .activityDays:
            return AppEndpoints.Reflect.activityDays
        case .posts:
            return AppEndpoints.Reflect.posts
        }
    }
}

struct ReflectPostEndpoint: QFEndpoint {
    let path: String
    let bodyData: Data
    let idempotencyKey: String?

    var route: QFApiClient.RequestRoute { .user }
    var method: QFHTTPMethod { .post }
}

struct ReflectPatchEndpoint: QFEndpoint {
    let path: String
    let bodyData: Data

    var route: QFApiClient.RequestRoute { .user }
    var method: QFHTTPMethod { .patch }
}
