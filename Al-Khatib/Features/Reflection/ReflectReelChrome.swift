//
// ReflectReelChrome.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

enum ReflectReelChrome {
    static let gradient = LinearGradient(
        colors: [
            Color.Token.forestDark,
            Color.Token.deepEmerald,
            Color.Token.forestDeeper
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let fillColor = Color.Token.forestDeeper
    static let ambientTeal = Color.Token.teal
    static let ambientGold = Color.Token.goldBright
    static let ambientEmerald = Color.Token.emeraldRich
    static let cardBorderGradient = LinearGradient(
        colors: [
            Color.Token.goldBright.opacity(0.45),
            Color.Token.gold.opacity(0.2),
            Color.Token.goldBright.opacity(0.1),
            Color.white.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardShadowColor = Color.Token.goldBright.opacity(0.12)
}
