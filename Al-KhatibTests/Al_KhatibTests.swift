//
//  Al_KhatibTests.swift
//  Al-KhatibTests
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Testing
@testable import Al_Khatib

struct Al_KhatibTests {

    @Test func randomAyahPayloadDecodesTajweedField() throws {
        let json = """
        {
          "verse_key": "2:172",
          "text_uthmani_tajweed": "يَ<tajweed class=madda_obligatory>ـٰٓ</tajweed>أَيُّهَا"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let payload = try decoder.decode(RandomAyahPayload.self, from: json)
        #expect(payload.textUthmaniTajweed?.contains("tajweed") == true)
        #expect(payload.tajweedWebHTMLFragment().contains("tajweed"))
    }

    @Test func translationsResponseDecodesCorrectly() throws {
        let json = """
        {
          "translations": [
            {
              "id": 131,
              "name": "Dr. Mustafa Khattab, the Clear Quran",
              "author_name": "Dr. Mustafa Khattab",
              "slug": "clearquran-with-tafsir",
              "language_name": "english",
              "translated_name": {
                "name": "Dr. Mustafa Khattab",
                "language_name": "english"
              }
            }
          ]
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(TranslationsResponse.self, from: json)
        #expect(response.translations.count == 1)
        
        let first = try #require(response.translations.first)
        #expect(first.id == 131)
        #expect(first.name == "Dr. Mustafa Khattab, the Clear Quran")
        #expect(first.authorName == "Dr. Mustafa Khattab")
        #expect(first.slug == "clearquran-with-tafsir")
        #expect(first.languageName == "english")
        #expect(first.translatedName?.name == "Dr. Mustafa Khattab")
        #expect(first.translatedName?.languageName == "english")
    }

    @Test func translationsSortingLogicWorksCorrectly() {
        let t1 = QFTranslation(id: 1, name: "Trans A", authorName: "Author B", slug: "slug-a", languageName: "indonesian", translatedName: nil)
        let t2 = QFTranslation(id: 2, name: "Trans B", authorName: "Author A", slug: "slug-b", languageName: "english", translatedName: nil)
        let t3 = QFTranslation(id: 3, name: "Trans C", authorName: "Author C", slug: "slug-c", languageName: "indonesian", translatedName: nil)
        let t4 = QFTranslation(id: 4, name: "Trans D", authorName: "Author Z", slug: "slug-d", languageName: "english", translatedName: nil)
        let t5 = QFTranslation(id: 5, name: "Trans E", authorName: "Author A", slug: "slug-e", languageName: "french", translatedName: nil)

        let original = [t1, t2, t3, t4, t5]
        
        // Sorting logic copied exactly from TranslatorSelectionSheet:
        // Sort English first, then others alphabetically by language and author
        let sorted = original.sorted { a, b in
            if a.languageName == "english" && b.languageName != "english" {
                return true
            }
            if b.languageName == "english" && a.languageName != "english" {
                return false
            }
            if a.languageName == b.languageName {
                return a.authorName < b.authorName
            }
            return a.languageName < b.languageName
        }

        // Expected Order:
        // 1st: t2 (english, Author A)
        // 2nd: t4 (english, Author Z)
        // 3rd: t5 (french, Author A)
        // 4th: t1 (indonesian, Author B)
        // 5th: t3 (indonesian, Author C)
        #expect(sorted.map(\.id) == [2, 4, 5, 1, 3])
    }

}

