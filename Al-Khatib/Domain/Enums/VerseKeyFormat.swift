//
//  VerseKeyFormat.swift
//  Al-Khatib
//

import Foundation

enum VerseKeyFormat {
    static func canonical(from raw: String) -> String {
        if raw.hasPrefix("surah-") {
            let rest = String(raw.dropFirst("surah-".count))
            guard let colon = rest.firstIndex(of: ":") else { return raw }
            let chapterAyah = rest[..<colon]
            let segments = chapterAyah.split(separator: "-")
            if segments.count >= 2,
               let chapter = Int(segments[0]),
               let ayah = Int(segments[segments.count - 1]) {
                return "\(chapter):\(ayah)"
            }
        }
        return raw
    }

    @MainActor
    static func humanLabel(for verseKey: String) -> String {
        let key = canonical(from: verseKey)
        let parts = key.split(separator: ":")
        guard parts.count == 2,
              let chapter = Int(parts[0]),
              let ayah = Int(parts[1]) else {
            return verseKey
        }
        let surahName = ChapterCatalog.displayName(forChapterId: chapter) ?? "Surah \(chapter)"
        return "\(surahName)・\(ayah)"
    }
}
