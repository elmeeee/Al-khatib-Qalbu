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

    var bodyData: Data? { nil }
}

struct ReflectPostEndpoint: QFEndpoint {
    let path: String
    let payload: Data
    let idempotencyKey: String?

    var route: QFApiClient.RequestRoute { .user }
    var method: QFHTTPMethod { .post }
    var bodyData: Data? { payload }

    init(path: String, bodyData: Data, idempotencyKey: String? = nil) {
        self.path = path
        self.payload = bodyData
        self.idempotencyKey = idempotencyKey
    }
}

struct ReflectPatchEndpoint: QFEndpoint {
    let path: String
    let payload: Data

    var route: QFApiClient.RequestRoute { .user }
    var method: QFHTTPMethod { .patch }
    var bodyData: Data? { payload }

    init(path: String, bodyData: Data) {
        self.path = path
        self.payload = bodyData
    }
}

struct ReflectFeedEndpoint: QFEndpoint {
    let page: Int
    let limit: Int

    var route: QFApiClient.RequestRoute { .user }
    var method: QFHTTPMethod { .get }
    var path: String { AppEndpoints.Reflect.postsFeed }

    var query: [URLQueryItem] {
        [
            URLQueryItem(name: "tab", value: "feed"),
            URLQueryItem(name: "sortBy", value: "latest"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "filter[postTypeIds]", value: "1")
        ]
    }

    var bodyData: Data? { nil }
}

struct ReflectMyPostsEndpoint: QFEndpoint {
    let page: Int
    let limit: Int

    var route: QFApiClient.RequestRoute { .user }
    var method: QFHTTPMethod { .get }
    var path: String { AppEndpoints.Reflect.postsMyPosts }

    var query: [URLQueryItem] {
        [
            URLQueryItem(name: "tab", value: "my_reflections"),
            URLQueryItem(name: "sortBy", value: "latest"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
    }

    var bodyData: Data? { nil }
}

struct ReflectToggleLikeEndpoint: QFEndpoint {
    let postId: String

    var route: QFApiClient.RequestRoute { .user }
    var method: QFHTTPMethod { .post }
    var path: String { AppEndpoints.Reflect.postToggleLike(postId) }
    var bodyData: Data? { nil }
}
