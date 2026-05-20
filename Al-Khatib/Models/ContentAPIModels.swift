//
//  ContentAPIModels.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
internal import UIKit

struct RandomAyahResponse: Decodable, Sendable {
    let verse: RandomAyahPayload?
}

struct RandomAyahPayload: Decodable, Sendable {
    let id: Int?
    let verseNumber: Int?
    let verseKey: String?
    let textIndopak: String?
    let textImlaeiSimple: String?
    let textImlaei: String?
    let textUthmani: String?
    let textUthmaniSimple: String?
    let textUthmaniTajweed: String?
    let textQpcHafs: String?
    let textQpcNastaleeqHafs: String?
    let textQpcNastaleeq: String?
    let textIndopakNastaleeq: String?
    let pageNumber: Int?
    let juzNumber: Int?
    let audio: AudioPayload?
    let translations: [InlineTranslation]?
    
    var displayText: String? {
        guard let raw = textUthmaniTajweed?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           raw.isEmpty == false else {
            return nil
        }
        let text = raw.containsHTMLMarkup ? raw.strippingHTMLToPlainText() : raw
        return text.normalizedForQuranRenderingPreservingResponse()
    }

    func tajweedWebHTMLFragment() -> String {
        let markerHtml = QuranAyahEndBadge.html(forAyahNumber: effectiveAyahNumber)
        let spacer = markerHtml.isEmpty ? "" : " "

        guard let raw = textUthmaniTajweed?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           raw.isEmpty == false else {
            return "<div dir=\"rtl\" lang=\"ar\"></div>"
        }

        var body = raw
        if raw.containsAyahEndSpanMarkup {
            let stripped = raw.strippingHTMLSpansMatchingClassEnd
            if stripped.isEmpty == false {
                body = stripped
            }
        }
        return "<div dir=\"rtl\" lang=\"ar\">\(body)\(spacer)\(markerHtml)</div>"
    }

    var resolvedVerseNumber: Int? {
        if let n = verseNumber, n > 0 { return n }
        guard let vk = verseKey?.split(separator: ":").last else { return nil }
        return Int(String(vk)).flatMap { $0 > 0 ? $0 : nil }
    }

    private var effectiveAyahNumber: Int? {
        resolvedVerseNumber
    }

    var listIdentity: String {
        if let verseKey, verseKey.isEmpty == false { return verseKey }
        if let id { return "id-\(id)" }
        if let verseNumber { return "ayah-\(verseNumber)" }
        return "verse-\(verseNumber ?? 0)"
    }
}

private enum QuranAyahEndBadge {
    
    static let rosette = "\u{06DD}"
    static func easternArabicIndicDigits(_ value: Int) -> String {
        let table = ["\u{0660}", "\u{0661}", "\u{0662}", "\u{0663}", "\u{0664}", "\u{0665}", "\u{0666}", "\u{0667}", "\u{0668}", "\u{0669}"]
        guard value > 0 else { return table[0] }
        var n = value
        var chars: [String] = []
        while n > 0 {
            chars.append(table[n % 10])
            n /= 10
        }
        return chars.reversed().joined()
    }

    static func html(forAyahNumber n: Int?) -> String {
        guard let n, n > 0 else { return "" }
        let digits = easternArabicIndicDigits(n)
        return """
        <span lang="ar" dir="rtl" class="ayah-end-symbol" aria-label="Ayah \(n)">
            <span class="ayah-end-rosette" aria-hidden="true">\(rosette)</span><span class="ayah-end-number">\(digits)</span>
        </span>
        """
    }

    static func appendNativeMarker(to arabic: String, ayahNumber: Int?) -> String {
        guard let n = ayahNumber, n > 0 else { return arabic }
        return "\(arabic) \(rosette)\u{200C}\(easternArabicIndicDigits(n))"
    }
}

private extension String {
    var strippingHTMLSpansMatchingClassEnd: String {
        let pattern = #"<span\b[^>]*\bclass\s*=\s*['"]?\s*end\s*['"]?[^>]*>[\s\S]*?</span>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return self
        }
        let range = NSRange(startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var containsHTMLMarkup: Bool {
        range(of: #"<[a-zA-Z][^>]*>"#, options: .regularExpression) != nil
    }

    var containsAyahEndSpanMarkup: Bool {
        if localizedCaseInsensitiveContains("class=\"end\"") { return true }
        if localizedCaseInsensitiveContains("class='end'") { return true }
        return range(of: #"class\s*=\s*['"]?\s*end\b"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    var htmlEscapedForWebBody: String {
        var out = ""
        out.reserveCapacity(count)
        for scalar in unicodeScalars {
            switch scalar {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            default: out.unicodeScalars.append(scalar)
            }
        }
        return out
    }

    func strippingHTMLToPlainText() -> String {
        guard containsHTMLMarkup else { return self }
        guard let data = data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string
        }
        return self
    }

    func normalizedForQuranRenderingPreservingResponse() -> String {
        precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }
}

struct InlineTranslation: Decodable, Sendable {
    let id: Int?
    let resourceId: Int?
    let text: String?
    let resourceName: String?

    enum CodingKeys: String, CodingKey {
        case id, text
        case resourceId
        case resourceName
    }
}

struct AudioPayload: Decodable, Sendable {
    let url: String?
}

struct TafsirResponse: Decodable, Sendable {
    let tafsir: TafsirPayload?
}

struct TafsirPayload: Decodable, Sendable {
    let id: Int?
    let text: String?
    let resourceId: Int?
    let resourceName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, text
        case resourceId
        case resourceName
    }

    var textStrippingHTML: String? {
        guard let text = text, let data = text.data(using: .utf8) else { return text }
        if let attr = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ) {
            return attr.string
        }
        return text
    }
}

struct HadithsByAyahResponse: Decodable, Sendable {
    let hadiths: [HadithReference]?
    let page: Int?
    let limit: Int?
    let hasMore: Bool?
    let language: String?
    let direction: String?
}

struct HadithReference: Decodable, Sendable {
    let urn: Int?
    let collection: String?
    let bookNumber: String?
    let chapterId: String?
    let hadithNumber: String?
    let name: String?
    let hadith: [HadithText]?
}

struct HadithText: Decodable, Sendable {
    let lang: String?
    let chapterNumber: String?
    let chapterTitle: String?
    let body: String?
    let urn: Int?
    let grades: [HadithGrade]?
}

struct HadithGrade: Decodable, Sendable {
    let gradedBy: String?
    let grade: String?
}

struct RecitationsResponse: Decodable, Sendable {
    let recitations: [RecitationPayload]?
}

struct RecitationPayload: Decodable, Sendable {
    let id: Int?
    let reciterName: String?
    let translatedName: RecitationTranslatedName?

    enum CodingKeys: String, CodingKey {
        case id
        case reciterName
        case translatedName
    }

    var identifiableId: Int { id ?? 0 }

    var displayName: String {
        return translatedName?.name ?? reciterName ?? "Reciter \(identifiableId)"
    }
}

struct RecitationTranslatedName: Decodable, Sendable {
    let name: String?
}

struct ChaptersResponse: Decodable, Sendable {
    let chapters: [QuranChapter]

    enum CodingKeys: String, CodingKey {
        case chapters
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        chapters = (try? c.decode([QuranChapter].self, forKey: .chapters)) ?? []
    }
}

struct QuranChapter: Decodable, Sendable, Identifiable, Hashable {
    let id: Int
    let revelationPlace: String?
    let revelationOrder: Int?
    let bismillahPre: Bool?
    let pages: [Int]?
    let nameSimple: String?
    let nameComplex: String?
    let nameArabic: String?
    let versesCount: Int?
    let translatedName: ChapterTranslatedName?

    var displayComplexName: String {
        if let nameComplex, nameComplex.isEmpty == false { return nameComplex }
        if let nameSimple, nameSimple.isEmpty == false { return nameSimple }
        return "Chapter \(id)"
    }

    var displayTranslatedName: String {
        translatedName?.name ?? ""
    }

    var displayTitle: String {
        let translated = displayTranslatedName
        if translated.isEmpty == false { return translated }
        return displayComplexName
    }

    var versesCountLabel: String? {
        guard let versesCount else { return nil }
        return versesCount == 1 ? "1 ayah" : "\(versesCount) ayahs"
    }

    var revelationLabel: String {
        guard let raw = revelationPlace?.trimmingCharacters(in: .whitespacesAndNewlines),
              raw.isEmpty == false else {
            return ""
        }
        switch raw.lowercased() {
        case "makkah", "mecca":
            return "Makkah"
        case "madinah", "medina":
            return "Madinah"
        default:
            return raw.capitalized
        }
    }

    var isMeccan: Bool {
        switch revelationPlace?.lowercased() {
        case "makkah", "mecca": true
        default: false
        }
    }
}

struct ChapterTranslatedName: Decodable, Sendable, Hashable {
    let languageName: String?
    let name: String?
}

struct VersesByChapterResponse: Decodable, Sendable {
    let verses: [RandomAyahPayload]
    let pagination: ContentPagination?

    enum CodingKeys: String, CodingKey {
        case verses, pagination
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        verses = (try? c.decode([RandomAyahPayload].self, forKey: .verses)) ?? []
        pagination = try? c.decode(ContentPagination.self, forKey: .pagination)
    }
}

struct ContentPagination: Decodable, Sendable {
    let perPage: Int?
    let currentPage: Int?
    let nextPage: Int?
    let totalPages: Int?
    let totalRecords: Int?


    var hasNextPage: Bool {
        guard let nextPage, let currentPage else { return false }
        return nextPage > currentPage
    }
}

struct QFTranslation: Decodable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let authorName: String
    let slug: String?
    let languageName: String
    let translatedName: TranslatedName?

    struct TranslatedName: Decodable, Hashable, Sendable {
        let name: String
        let languageName: String
    }

    init(
        id: Int,
        name: String,
        authorName: String,
        slug: String?,
        languageName: String,
        translatedName: TranslatedName?
    ) {
        self.id = id
        self.name = name
        self.authorName = authorName
        self.slug = slug
        self.languageName = languageName
        self.translatedName = translatedName
    }
}

struct TranslationsResponse: Decodable, Sendable {
    let translations: [QFTranslation]
}
