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

    @Test func chapterReaderPreferencesUsesSavedTranslationId() {
        let defaults = UserDefaults(suiteName: "ChapterReaderPreferencesTests")!
        defaults.removePersistentDomain(forName: "ChapterReaderPreferencesTests")
        defaults.set(86, forKey: ChapterReaderPreferences.translationIdKey)
        #expect(ChapterReaderPreferences.selectedTranslationId(defaults: defaults) == 86)
        #expect(ChapterReaderPreferences.selectedTranslationIdQueryValue(defaults: defaults) == "86")
    }

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

    @Test func translationsResponseDecodesNullSlugFromAPI() throws {
        let json = """
        {
          "translations": [
            {
              "author_name": "Montada Islamic Foundation",
              "id": 136,
              "language_name": "french",
              "name": "Montada Islamic Foundation",
              "slug": null,
              "translated_name": {
                "language_name": "english",
                "name": "Montada Islamic Foundation"
              }
            },
            {
              "author_name": "Abdul Haleem",
              "id": 85,
              "language_name": "english",
              "name": "M.A.S. Abdel Haleem",
              "slug": "en-haleem",
              "translated_name": {
                "language_name": "english",
                "name": "M.A.S. Abdel Haleem"
              }
            }
          ]
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(TranslationsResponse.self, from: json)
        #expect(response.translations.count == 2)
        #expect(response.translations[0].slug == nil)
        #expect(response.translations[1].slug == "en-haleem")
    }

    @Test func chaptersResponseDecodesRevelationPlace() throws {
        let json = """
        {
          "chapters": [
            {
              "bismillah_pre": false,
              "id": 1,
              "name_arabic": "الفاتحة",
              "name_complex": "Al-Fātiĥah",
              "name_simple": "Al-Fatihah",
              "pages": [1, 1],
              "revelation_order": 5,
              "revelation_place": "makkah",
              "translated_name": { "language_name": "english", "name": "The Opener" },
              "verses_count": 7
            },
            {
              "bismillah_pre": true,
              "id": 2,
              "name_arabic": "البقرة",
              "name_complex": "Al-Baqarah",
              "name_simple": "Al-Baqarah",
              "pages": [2, 49],
              "revelation_order": 87,
              "revelation_place": "madinah",
              "translated_name": { "language_name": "english", "name": "The Cow" },
              "verses_count": 286
            }
          ]
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(ChaptersResponse.self, from: json)
        #expect(response.chapters.count == 2)
        #expect(response.chapters[0].revelationPlace == "makkah")
        #expect(response.chapters[1].revelationPlace == "madinah")
        #expect(response.chapters[0].revelationOrder == 5)
        #expect(response.chapters[1].bismillahPre == true)
        #expect(response.chapters[0].revelationLabel == "Makkah")
        #expect(response.chapters[1].revelationLabel == "Madinah")
        #expect(response.chapters[0].isMeccan == true)
        #expect(response.chapters[1].isMeccan == false)
    }

    @Test @MainActor func humanLabelUsesChapterCatalogFromAPI() throws {
        let json = """
        {
          "chapters": [{
            "id": 2,
            "name_complex": "Al-Baqarah",
            "name_simple": "Al-Baqarah",
            "revelation_place": "madinah",
            "verses_count": 286
          }]
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(ChaptersResponse.self, from: json)
        ChapterCatalog.register(response.chapters)
        #expect(VerseKeyFormat.humanLabel(for: "2:255") == "Al-Baqarah・255")
        ChapterCatalog.clear()
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

