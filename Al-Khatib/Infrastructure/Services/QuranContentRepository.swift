//
//  QuranContentRepository.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct QuranContentRepository: Sendable {
    private let client: QFApiClient
    private let local = LocalQuranDataSource()
    private let hadithLocal = LocalHadithDataSource()

    init(client: QFApiClient) {
        self.client = client
    }

    func getChapters(language: String = "en") async throws -> [QuranChapter] {
        let normalizedLang = language.hasPrefix("id") ? "id" : "en"
        let chapters = try await local.getChapters(language: normalizedLang)
        await MainActor.run { ChapterCatalog.register(chapters) }
        return chapters
    }

    func getVersesByChapter(
        chapterNumber: Int,
        recitationId: Int = 6,
        page: Int = 1,
        perPage: Int = 50
    ) async throws -> VersesByChapterResponse {
        let normalizedTranslationId = normalizeTranslationId(ChapterReaderPreferences.selectedTranslationId())
        let normalizedRecitationId = normalizeRecitationId(recitationId)
        return try await local.getVersesByChapter(
            chapterNumber: chapterNumber,
            page: page,
            perPage: perPage,
            translationId: normalizedTranslationId,
            recitationId: normalizedRecitationId
        )
    }

    func getRandomAyah(
        recitationId: Int = 6
    ) async throws -> RandomAyahResponse {
        let normalizedTranslationId = normalizeTranslationId(ChapterReaderPreferences.selectedTranslationId())
        let normalizedRecitationId = normalizeRecitationId(recitationId)
        if let payload = try await local.getRandomAyah(translationId: normalizedTranslationId, recitationId: normalizedRecitationId) {
            return RandomAyahResponse(verse: payload)
        }
        throw NSError(domain: "LocalQuran", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load random Ayah."])
    }

    func getTafsirByAyah(resourceId: String, ayahKey: String) async throws -> TafsirResponse {
        let localId = (resourceId == "16" || resourceId == "jalalayn") ? "jalalayn" : "local"
        if let payload = try await local.getTafsirByAyah(ayahKey: ayahKey, resourceId: localId) {
            return TafsirResponse(tafsir: payload)
        }
        throw NSError(domain: "LocalQuran", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load Tafsir."])
    }

    func getHadithsByAyah(
        ayahKey: String,
        language: String = "en",
        page: Int = 1,
        limit: Int = 4
    ) async throws -> HadithsByAyahResponse {
        return try await hadithLocal.getHadithsByAyah(ayahKey: ayahKey, page: page, limit: limit, language: language) {
            let clampedLimit = min(max(limit, 1), 5)
            let query: [URLQueryItem] = [
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "page", value: String(max(page, 1))),
                URLQueryItem(name: "limit", value: String(clampedLimit))
            ]
            return try await client.send(
                QuranContentEndpoint.hadithsByAyah(ayahKey: ayahKey, query: query)
            )
        }
    }

    func getRecitations() async throws -> RecitationsResponse {
        let recs = [
            RecitationPayload(id: 1, reciterName: "alafasy", translatedName: RecitationTranslatedName(name: "Mishary Rashid Alafasy")),
            RecitationPayload(id: 2, reciterName: "husarymujawwad", translatedName: RecitationTranslatedName(name: "Mahmoud Khalil Al-Husary")),
            RecitationPayload(id: 3, reciterName: "minshawi", translatedName: RecitationTranslatedName(name: "Muhammad Siddiq Al-Minshawi")),
            RecitationPayload(id: 4, reciterName: "muhammadjibreel", translatedName: RecitationTranslatedName(name: "Muhammad Jibreel")),
            RecitationPayload(id: 5, reciterName: "ahmedajamy", translatedName: RecitationTranslatedName(name: "Ahmed Al-Ajamy")),
            RecitationPayload(id: 6, reciterName: "muhammadayyoub", translatedName: RecitationTranslatedName(name: "Muhammad Ayyoub"))
        ]
        return RecitationsResponse(recitations: recs)
    }

    func getTranslations(language: String = "en") async throws -> TranslationsResponse {
        let trans = [
            QFTranslation(id: 1, name: "Indonesian", authorName: "Kementerian Agama RI", slug: "id", languageName: "indonesian", translatedName: QFTranslation.TranslatedName(name: "Indonesian", languageName: "indonesian")),
            QFTranslation(id: 2, name: "Sahih International", authorName: "Sahih International", slug: "en", languageName: "english", translatedName: QFTranslation.TranslatedName(name: "Sahih International", languageName: "english")),
            QFTranslation(id: 3, name: "Malay", authorName: "DBP", slug: "my", languageName: "malay", translatedName: QFTranslation.TranslatedName(name: "Malay", languageName: "malay")),
            QFTranslation(id: 4, name: "Kemenag (Arab Latin)", authorName: "Kementerian Agama RI", slug: "kemenag", languageName: "indonesian", translatedName: QFTranslation.TranslatedName(name: "Kemenag", languageName: "indonesian"))
        ]
        return TranslationsResponse(translations: trans)
    }

    func getVerseByKey(verseKey: String) async throws -> SingleVerseResponse {
        let normalizedTranslationId = normalizeTranslationId(ChapterReaderPreferences.selectedTranslationId())
        if let payload = try await local.getVerseByKey(verseKey, translationId: normalizedTranslationId, recitationId: 6) {
            return SingleVerseResponse(verse: payload)
        }
        throw NSError(domain: "LocalQuran", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load verse."])
    }

    // Normalizers
    private func normalizeTranslationId(_ savedId: Int) -> Int {
        switch savedId {
        case 1, 2, 3, 4: return savedId
        case 22, 131, 33: return 1 // Indonesian
        case 20, 84: return 2 // English
        default: return 1
        }
    }

    private func normalizeRecitationId(_ savedId: Int) -> Int {
        if (1...6).contains(savedId) { return savedId }
        // Map legacy QF IDs (e.g. 7 or other ones)
        return 1
    }
}
