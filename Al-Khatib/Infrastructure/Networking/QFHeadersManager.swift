//
//  QFHeadersManager.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum QFHeadersManager {
    static func apply(
        to request: inout URLRequest,
        token: String,
        clientId: String,
        extraHeaders: [String: String] = [:]
    ) {
        request.setValue(token, forHTTPHeaderField: "x-auth-token")
        request.setValue(clientId, forHTTPHeaderField: "x-client-id")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (header, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }
    }
}
