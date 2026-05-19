//
//  QuranContentEndpoints.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum QuranContentEndpoint: QFEndpoint {
    case randomAyah(query: [URLQueryItem])
    case resourcesRecitations(query: [URLQueryItem])
    case tafsirByAyah(resourceId: String, ayahKey: String, query: [URLQueryItem])

    var route: QFApiClient.RequestRoute { .content }
    var method: QFHTTPMethod { .get }

    var path: String {
        switch self {
        case .randomAyah:
            return AppEndpoints.Content.versesRandom
        case .resourcesRecitations:
            return AppEndpoints.Content.resourcesRecitations
        case .tafsirByAyah(let resourceId, let ayahKey, _):
            return AppEndpoints.Content.tafsirByAyah(resourceId: resourceId, ayahKey: ayahKey)
        }
    }

    var query: [URLQueryItem] {
        switch self {
        case .randomAyah(let query),
             .resourcesRecitations(let query),
             .tafsirByAyah(_, _, let query):
            return query
        }
    }

    var bodyData: Data? { nil }
}
