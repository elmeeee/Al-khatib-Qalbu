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
    let textUthmani: String?
    let textUthmaniTajweed: String?
    let pageNumber: Int?
    let juzNumber: Int?
    let audio: AudioPayload?
    let translations: [InlineTranslation]?

    enum CodingKeys: String, CodingKey {
        case id, audio, translations
        case verseNumber
        case verseKey
        case textIndopak
        case textUthmani
        case textUthmaniTajweed
        case pageNumber
        case juzNumber
    }
    
    var displayText: String? {
        let raw = textUthmaniTajweed?.strippingHTMLToPlainText()
            ?? textIndopak
            ?? textUthmani
        return raw?
            .normalizedForQuranRenderingPreservingResponse()
    }

    /// HTML for `WKWebView`: raw tajweed markup when present, otherwise escaped plain `displayText`.
    /// Appends ۝ U+06DD + Eastern Arabic‑Indic digits for the ayah number (and removes redundant API `span.class=end` badges).
    func arabicFragmentForWebView() -> String {
        let markerHtml = QuranAyahEndBadge.html(forAyahNumber: effectiveAyahNumber)

        if let tajweed = textUthmaniTajweed?.trimmingCharacters(in: .whitespacesAndNewlines), tajweed.isEmpty == false {
            let body = tajweed.strippingHTMLSpansMatchingClassEnd
            let spacer = markerHtml.isEmpty ? "" : " "
            return body + spacer + markerHtml
        }
        let plain = displayText ?? ""
        let inner = markerHtml.isEmpty
            ? plain.htmlEscapedForAttribute
            : "\(plain.htmlEscapedForAttribute) \(markerHtml)"
        return "<div dir=\"rtl\" lang=\"ar\">\(inner)</div>"
    }

    private var effectiveAyahNumber: Int? {
        if let n = verseNumber, n > 0 { return n }
        guard let vk = verseKey?.split(separator: ":").last else { return nil }
        return Int(String(vk)).flatMap { $0 > 0 ? $0 : nil }
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

    /// Minimal escaping so plain Arabic survives inside HTML fragments.
    var htmlEscapedForAttribute: String {
        map { ch -> String in
            switch ch {
            case "&": return "&amp;"
            case "<": return "&lt;"
            case ">": return "&gt;"
            case "\"": return "&quot;"
            default: return String(ch)
            }
        }.joined()
    }

    func strippingHTMLToPlainText() -> String {
        guard let data = data(using: .utf8) else { return self }
        if let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ) {
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

    var displayName: String {
        return translatedName?.name ?? reciterName ?? "Reciter \(id ?? 0)"
    }
}

struct RecitationTranslatedName: Decodable, Sendable {
    let name: String?
}
