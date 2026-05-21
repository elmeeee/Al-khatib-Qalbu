//
//  PrayerThematicTheme.swift
//  Al-Khatib
//
//  Contextual visual theme for the prayer dashboard (day vs night).
//  Composes palette values from `Color.Token` — not raw hex.
//

import SwiftUI

enum PrayerThematicTheme: Equatable, Sendable {
    case daylight
    case night

    var gradientColors: [Color] {
        switch self {
        case .daylight:
            [Color.Token.prayerCream, Color.Token.prayerCreamWarm, Color.Token.prayerMint]
        case .night:
            [Color.Token.slate900, Color.Token.slate800, Color.Token.indigoDeep]
        }
    }

    var cardGradientColors: [Color] {
        switch self {
        case .daylight:
            [Color.Token.deepEmerald, Color.Token.tealDark]
        case .night:
            [Color.Token.emeraldNight, Color.Token.deepEmerald]
        }
    }

    var textColor: Color { .white }

    var secondaryTextColor: Color { .white.opacity(0.7) }

    var borderGradientColors: [Color] {
        [Color.white.opacity(0.2), Color.white.opacity(0.05)]
    }

    var mascotImageName: String {
        switch self {
        case .daylight: "mascot_daylight"
        case .night: "mascot_night"
        }
    }

    /// Maps active prayer slot to dashboard theme.
    static func forActivePrayer(_ name: String) -> PrayerThematicTheme {
        name == "Maghrib" || name == "Isha" ? .night : .daylight
    }
}
