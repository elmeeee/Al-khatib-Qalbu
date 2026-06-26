//
//  QFConfiguration.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct QFConfiguration: Sendable {
    var authBaseURL: URL
    var oauthAuthorizeURL: URL
    var oauthRedirectURI: URL
    var oauthAppRedirectURI: URL
    var oauthScopes: String
    var contentAPIBaseURL: URL
    var userAPIBaseURL: URL
    var clientId: String
    var clientSecret: String?
    var defaultTranslationId: Int
    var appGroupIdentifier: String

}
