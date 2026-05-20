//
//  QuranArabicTextStyle.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

/// Content API `fields` values for Arabic script variants.
enum QuranArabicTextStyle: String, CaseIterable, Sendable, Identifiable {
    case indopak = "text_indopak"
    case imlaeiSimple = "text_imlaei_simple"
    case imlaei = "text_imlaei"
    case uthmani = "text_uthmani"
    case uthmaniSimple = "text_uthmani_simple"
    case uthmaniTajweed = "text_uthmani_tajweed"
    case qpcHafs = "text_qpc_hafs"
    case qpcNastaleeqHafs = "text_qpc_nastaleeq_hafs"
    case qpcNastaleeq = "text_qpc_nastaleeq"
    case indopakNastaleeq = "text_indopak_nastaleeq"

    static let storageKey = "chapterReaderArabicTextStyle"
    static let defaultStyle: QuranArabicTextStyle = .uthmaniTajweed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .indopak: "Indopak"
        case .imlaeiSimple: "Imlaei simple"
        case .imlaei: "Imlaei"
        case .uthmani: "Uthmani"
        case .uthmaniSimple: "Uthmani simple"
        case .uthmaniTajweed: "Uthmani tajweed"
        case .qpcHafs: "QPC Hafs"
        case .qpcNastaleeqHafs: "QPC Nastaleeq Hafs"
        case .qpcNastaleeq: "QPC Nastaleeq"
        case .indopakNastaleeq: "Indopak Nastaleeq"
        }
    }

    var usesTajweedMarkup: Bool {
        self == .uthmaniTajweed
    }

    static func savedOrDefault() -> QuranArabicTextStyle {
        guard let raw = UserDefaults.standard.string(forKey: storageKey),
              let style = QuranArabicTextStyle(rawValue: raw) else {
            return defaultStyle
        }
        return style
    }

    func persist() {
        UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
    }
}
