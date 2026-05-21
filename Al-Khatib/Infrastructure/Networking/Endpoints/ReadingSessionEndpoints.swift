//
//  ReadingSessionEndpoints.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct ReadingSessionGetEndpoint: QFEndpoint {
    let queryItems: [URLQueryItem]

    var route: QFApiClient.RequestRoute { .authV1User }
    var method: QFHTTPMethod { .get }
    var path: String { AppEndpoints.AuthV1.readingSessions }
    var query: [URLQueryItem] { queryItems }
    var bodyData: Data? { nil }
}

struct ReadingSessionPostEndpoint: QFEndpoint {
    let payload: Data

    var route: QFApiClient.RequestRoute { .authV1User }
    var method: QFHTTPMethod { .post }
    var path: String { AppEndpoints.AuthV1.readingSessions }
    var bodyData: Data? { payload }
}
