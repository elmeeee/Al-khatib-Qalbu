//
//  QFEndpoint.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum QFHTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

protocol QFEndpoint {
    var route: QFApiClient.RequestRoute { get }
    var method: QFHTTPMethod { get }
    var path: String { get }
    var query: [URLQueryItem] { get }
    var headers: [String: String] { get }
    var bodyData: Data? { get }
    var idempotencyKey: String? { get }
}

extension QFEndpoint {
    var query: [URLQueryItem] { [] }
    var headers: [String: String] { [:] }
    var bodyData: Data? { nil }
    var idempotencyKey: String? { nil }
}
