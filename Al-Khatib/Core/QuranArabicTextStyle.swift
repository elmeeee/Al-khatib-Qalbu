//
//  QuranArabicTextStyle.swift
//  Al-Khatib
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

    enum ScriptCategory: Sendable {
        case uthmaniTajweed
        case uthmani
        case imlaei
        case indopak
        case qpc
        case nastaleeq
    }

    var category: ScriptCategory {
        switch self {
        case .uthmaniTajweed: .uthmaniTajweed
        case .uthmani, .uthmaniSimple: .uthmani
        case .imlaei, .imlaeiSimple: .imlaei
        case .indopak: .indopak
        case .qpcHafs: .qpc
        case .qpcNastaleeq, .qpcNastaleeqHafs, .indopakNastaleeq: .nastaleeq
        }
    }

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

    /// Bundled tajweed font — only for Uthmani tajweed field markup.
    var shouldEmbedTajweedWebFont: Bool {
        category == .uthmaniTajweed
    }

    /// CSS `font-family` stack tuned per script (falls back to system Arabic fonts on iOS).
    /// Pass `embeddingTajweedWebFont: true` only when `@font-face` for `AlKhatibQuranWeb` is embedded in the document.
    func webArabicFontStack(embeddingTajweedWebFont: Bool) -> String {
        if shouldEmbedTajweedWebFont, embeddingTajweedWebFont {
            return """
            'AlKhatibQuranWeb', 'KFGQPC HAFS Uthmanic Script', 'Amiri Quran', 'Scheherazade New', \
            'Geeza Pro', 'Noto Naskh Arabic', serif
            """
        }
        switch category {
        case .nastaleeq:
            return """
            'Noto Nastaliq Urdu', 'Al Tarikh', 'Urdu Typesetting', 'Geeza Pro', \
            'Noto Naskh Arabic', serif
            """
        case .qpc:
            return """
            'KFGQPC HAFS Uthmanic Script', 'Amiri Quran', 'Scheherazade New', \
            'KFGQPC Uthmanic Script HAFS', 'Geeza Pro', serif
            """
        case .imlaei:
            return """
            'KFGQPC Uthmanic Script HAFS', 'Damascus', 'Geeza Pro', \
            'Noto Naskh Arabic', 'Arial', serif
            """
        case .indopak:
            return """
            'Noto Naskh Arabic', 'Damascus', 'Geeza Pro', 'Arial', serif
            """
        case .uthmani, .uthmaniTajweed:
            return """
            'KFGQPC HAFS Uthmanic Script', 'Amiri Quran', 'Scheherazade New', \
            'Geeza Pro', 'Noto Naskh Arabic', serif
            """
        }
    }

    var webLineHeight: Double {
        switch category {
        case .nastaleeq: 2.05
        case .imlaei: 1.78
        case .indopak: 1.88
        default: 1.82
        }
    }

    var webFontSizeScale: Double {
        switch category {
        case .nastaleeq: 1.06
        case .qpc: 1.02
        default: 1.0
        }
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
