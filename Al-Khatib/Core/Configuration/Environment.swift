//
//  Environment.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum AppEnvironment: String, Sendable, CaseIterable {
    case development = "DEVELOPMENT"
    case production = "PRODUCTION"

    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}
