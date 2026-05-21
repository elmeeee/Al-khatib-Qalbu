//
//  DesignTokens.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

extension Color {
    enum Token {
        static let deepEmerald = Color(hex: "#064E3B")
        static let teal = Color(hex: "#0D9488")
        static let tealDark = Color(hex: "#0F766E")
        static let emeraldRich = Color(hex: "#065F46")
        static let emeraldNight = Color(hex: "#022C22")
        static let forestDark = Color(hex: "#0B3D34")
        static let forestDeeper = Color(hex: "#051F1A")
        static let readerMoss = Color(hex: "#0A3D2E")
        static let readerForest = Color(hex: "#0F2A22")
        static let gold = Color(hex: "#B45309")
        static let goldBright = Color(hex: "#D4A017")
        static let goldDeep = Color(hex: "#D97706")
        static let amberWash = Color(hex: "#FFFBEB")
        static let offWhite = Color(hex: "#F9F9F8")
        static let screenBackground = Color(hex: "#F8FAFC")
        static let pureWhite = Color.white
        static let softGrey = Color(hex: "#E5E7EB")
        static let lightGrey = Color(hex: "#F3F4F6")
        static let slate500 = Color(hex: "#64748B")
        static let slate800 = Color(hex: "#1E293B")
        static let slate900 = Color(hex: "#0F172A")
        static let prayerCream = Color(hex: "#FFF7ED")
        static let prayerCreamWarm = Color(hex: "#FEF3C7")
        static let prayerMint = Color(hex: "#F0FDFA")
        static let indigoDeep = Color(hex: "#312E81")
        static let sageMist = Color(hex: "#F1F5F2")
        static let sageTint = Color(hex: "#E7F0DF")
        static let panelGrey = Color(hex: "#E8EBEF")
        static let panelGreyAlt = Color(hex: "#EEF2EE")
        static let mintWash = Color(hex: "#F0FDF4")
        static let blueLink = Color(hex: "#2563EB")
        static let indigoAccent = Color(hex: "#4F46E5")
        static let danger = Color(hex: "#EF4444")
    }

    enum Theme {
        static let deepEmerald = Token.deepEmerald
        static let offWhite = Token.offWhite
        static let pureWhite = Token.pureWhite
        static let gold = Token.gold
        static let softGrey = Token.softGrey
        static let lightGrey = Token.lightGrey
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
