//
//  QuranChapterSearch.swift
//  Al-Khatib
//
//  Created by Elmee on 26/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

// MARK: - Public API

extension Array where Element == QuranChapter {
    /// Filter and rank chapters by a user-supplied query string.
    /// Matches by number, name (latin/arabic), translated name, and revelation place.
    func searchChapters(query: String) -> [QuranChapter] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.isEmpty == false else { return self }

        let normalized = normalizeLatin(q)

        // Revelation-place shortcut ("makkah" / "madinah" etc.)
        if let isMeccan = revelationFilterFor(normalized) {
            return filter { ($0.isMeccan) == isMeccan }
        }

        return compactMap { chapter -> (QuranChapter, Int)? in
            guard let score = scoreChapter(chapter, normalizedQuery: normalized) else { return nil }
            return (chapter, score)
        }
        .sorted {
            if $0.1 != $1.1 { return $0.1 > $1.1 }
            return $0.0.id < $1.0.id
        }
        .map(\.0)
    }
}

// MARK: - Private helpers

private func normalizeLatin(_ text: String) -> String {
    text
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        .replacingOccurrences(of: "[''`´]", with: "", options: .regularExpression)
        .replacingOccurrences(of: "[-–—]", with: " ", options: .regularExpression)
        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespaces)
}

private func stripArticle(_ text: String) -> String {
    for prefix in ["al ", "ar ", "as ", "at "] {
        if text.hasPrefix(prefix) { return String(text.dropFirst(prefix.count)) }
    }
    return text
}

private let revelationFilters: [String: Bool] = [
    "makkah": true, "mecca": true, "mekah": true, "mekkah": true,
    "madinah": false, "madina": false, "medina": false, "medinah": false
]

private func revelationFilterFor(_ normalized: String) -> Bool? {
    revelationFilters[normalized]
}

private extension QuranChapter {
    /// All searchable text fields, normalized + article-stripped.
    func searchFields() -> [String] {
        let raw: [String] = [
            "\(id)",
            displayComplexName,
            nameSimple ?? "",
            displayTranslatedName,
            revelationLabel,
            revelationPlace ?? ""
        ]
        .filter { !$0.isEmpty }
        .map { normalizeLatin($0) }

        let stripped = raw.map { stripArticle($0) }
        return Array(Set(raw + stripped)).filter { !$0.isEmpty }
    }
}

/// Scoring constants (match Android implementation)
private enum Score {
    static let exactNumber    = 1000
    static let alias          = 980
    static let exactName      = 900
    static let prefixName     = 850
    static let prefixTrans    = 820
    static let arabicMatch    = 750
    static let containsName   = 700
    static let containsTrans  = 650
    static let multiToken     = 500
    static let fallback       = 400
    static let numberPrefix   = 800
    static let revelationType = 320
}

private let chapterAliases: [String: Int] = [
    "fatihah": 1, "fatiha": 1, "al fatihah": 1, "opening": 1,
    "baqarah": 2, "bakara": 2,
    "imran": 3, "ali imran": 3,
    "nisa": 4, "nisaa": 4,
    "maidah": 5, "maeda": 5,
    "anam": 6,
    "araf": 7,
    "anfal": 8,
    "tawbah": 9, "tawba": 9, "repentance": 9,
    "yunus": 10, "jonah": 10,
    "hud": 11,
    "yusuf": 12, "joseph": 12,
    "kahf": 18, "cave": 18,
    "maryam": 19, "mary": 19,
    "yasin": 36, "ya sin": 36,
    "rahman": 55,
    "waqiah": 56, "waqi'ah": 56,
    "mulk": 67,
    "ikhlas": 112, "sincerity": 112,
    "falaq": 113,
    "nas": 114
]

private func scoreChapter(_ chapter: QuranChapter, normalizedQuery: String) -> Int? {
    let compact = normalizedQuery.replacingOccurrences(of: " ", with: "")
    let digitsOnly = compact.allSatisfy(\.isNumber)

    // Number match
    if digitsOnly, compact.isEmpty == false {
        if let num = Int(compact), num == chapter.id { return Score.exactNumber }
        if chapter.id.description.hasPrefix(compact) {
            return Score.numberPrefix - (chapter.id.description.count - compact.count) * 10
        }
        return nil
    }

    // Alias match
    if let aliasId = chapterAliases[normalizedQuery], aliasId == chapter.id {
        return Score.alias
    }

    // Token match — all tokens must appear in at least one search field
    let tokens = normalizedQuery.split(separator: " ").map(String.init).filter { !$0.isEmpty }
    guard tokens.isEmpty == false else { return nil }

    let fields = chapter.searchFields()
    let allMatch = tokens.allSatisfy { token in
        fields.contains { $0.contains(token) || $0.hasPrefix(token) }
    }
    guard allMatch else { return nil }

    let primary    = normalizeLatin(chapter.displayComplexName)
    let simple     = normalizeLatin(chapter.nameSimple ?? "")
    let translated = normalizeLatin(chapter.displayTranslatedName)

    var score: Int
    switch true {
    case primary == normalizedQuery || simple == normalizedQuery:
        score = Score.exactName
    case primary.hasPrefix(normalizedQuery) || simple.hasPrefix(normalizedQuery):
        score = Score.prefixName
    case translated.hasPrefix(normalizedQuery):
        score = Score.prefixTrans
    case primary.contains(normalizedQuery) || simple.contains(normalizedQuery):
        score = Score.containsName
    case translated.contains(normalizedQuery):
        score = Score.containsTrans
    case tokens.count > 1:
        score = Score.multiToken + tokens.count * 20
    default:
        score = Score.fallback
    }

    // Arabic boost
    if let arabic = chapter.nameArabic, arabic.contains(normalizedQuery) {
        score = max(score, Score.arabicMatch)
    }

    return score
}
