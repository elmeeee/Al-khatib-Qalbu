//
//  PublishOutcome.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum PublishOutcome: Sendable {
    case published
    case failed(message: String)
    case needsSignIn
}
