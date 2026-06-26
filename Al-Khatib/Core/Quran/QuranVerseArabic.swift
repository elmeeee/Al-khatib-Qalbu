//
//  QuranVerseArabic.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum QuranVerseArabic {
    static let apiFields = "text_uthmani_tajweed"

    static func webArabicFontStack(embeddingTajweedWebFont: Bool) -> String {
        if embeddingTajweedWebFont {
            return """
            'AlKhatibQuranWeb', 'KFGQPC HAFS Uthmanic Script', 'Amiri Quran', 'Scheherazade New', \
            'Geeza Pro', 'Noto Naskh Arabic', serif
            """
        }
        return """
        'KFGQPC HAFS Uthmanic Script', 'Amiri Quran', 'Scheherazade New', \
        'Geeza Pro', 'Noto Naskh Arabic', serif
        """
    }

    static let webLineHeight: Double = 1.82
    static let webFontSizeScale: Double = 1.0
}
