//
//  Configuration.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct AppConfiguration: Sendable {
    let environment: AppEnvironment
    let apiBaseURL: URL
    let userAPIBaseURL: URL
    let oauthEndpoint: URL
    let oauthAuthorizeEndpoint: URL
    let oauthRedirectURI: URL
    let oauthAppRedirectURI: URL
    let oauthScopes: String
    let clientId: String
    let clientSecret: String?
    let defaultTranslationId: Int
    let appGroupIdentifier: String

    var oauthBaseURL: URL {
        oauthEndpoint.deletingLastPathComponent().deletingLastPathComponent()
    }

    var qfConfiguration: QFConfiguration {
        QFConfiguration(
            authBaseURL: oauthBaseURL,
            oauthAuthorizeURL: oauthAuthorizeEndpoint,
            oauthRedirectURI: oauthRedirectURI,
            oauthAppRedirectURI: oauthAppRedirectURI,
            oauthScopes: oauthScopes,
            contentAPIBaseURL: apiBaseURL,
            userAPIBaseURL: userAPIBaseURL,
            clientId: clientId,
            clientSecret: clientSecret,
            defaultTranslationId: defaultTranslationId,
            appGroupIdentifier: appGroupIdentifier
        )
    }
}

private enum QFCompiledCredentials {
    static let appGroupIdentifier = "group.co.kamy.Al-Khatib"

    static func configuration(for environment: AppEnvironment) -> AppConfiguration {
        let apiBase = AppEndpoints.Runtime.apiBase
        return AppConfiguration(
            environment: environment,
            apiBaseURL: apiBase,
            userAPIBaseURL: apiBase,
            oauthEndpoint: AppEndpoints.Runtime.oauthToken,
            oauthAuthorizeEndpoint: AppEndpoints.Runtime.oauthAuthorize,
            oauthRedirectURI: AppEndpoints.Runtime.oauthCallback,
            oauthAppRedirectURI: AppEndpoints.Runtime.oauthAppCallback,
            oauthScopes: AppEndpoints.Runtime.oauthScopes,
            clientId: AppEndpoints.Runtime.oauthClientId,
            clientSecret: AppEndpoints.Runtime.oauthClientSecret,
            defaultTranslationId: AppEndpoints.Runtime.defaultTranslationId,
            appGroupIdentifier: appGroupIdentifier
        )
    }
}

extension AppEnvironment {
    var configuration: AppConfiguration {
        QFCompiledCredentials.configuration(for: self)
    }
}
