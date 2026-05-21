//
//  QuranContentRepository.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

private enum QuranVerseContentQuery {
    static let language = "en"
    static var translations: String {
        ChapterReaderPreferences.selectedTranslationIdQueryValue()
    }
    static let defaultRecitationId = 6
    static let translationFields = "resource_name"

    static func items(
        recitationId: Int = defaultRecitationId,
        page: Int? = nil,
        perPage: Int? = nil
    ) -> [URLQueryItem] {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "translations", value: translations),
            URLQueryItem(name: "audio", value: String(recitationId)),
            URLQueryItem(name: "fields", value: QuranVerseArabic.apiFields),
            URLQueryItem(name: "translation_fields", value: translationFields)
        ]
        if let page {
            query.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let perPage {
            let clamped = min(max(perPage, 1), 50)
            query.append(URLQueryItem(name: "per_page", value: String(clamped)))
        }
        return query
    }
}

struct QuranContentRepository: Sendable {
    private let client: QFApiClient

    init(client: QFApiClient) {
        self.client = client
    }

    func getChapters(language: String = "en") async throws -> [QuranChapter] {
        if let cached = await ChaptersCache.shared.get(language: language) {
            await MainActor.run { ChapterCatalog.register(cached) }
            return cached
        }
        let query = [URLQueryItem(name: "language", value: language)]
        let response: ChaptersResponse = try await client.send(
            QuranContentEndpoint.chapters(query: query)
        )
        let sorted = response.chapters.sorted { $0.id < $1.id }
        await ChaptersCache.shared.set(sorted, language: language)
        await MainActor.run { ChapterCatalog.register(sorted) }
        return sorted
    }

    func getVersesByChapter(
        chapterNumber: Int,
        recitationId: Int = QuranVerseContentQuery.defaultRecitationId,
        page: Int = 1,
        perPage: Int = 50
    ) async throws -> VersesByChapterResponse {
        let query = QuranVerseContentQuery.items(
            recitationId: recitationId,
            page: page,
            perPage: perPage
        )
        return try await client.send(
            QuranContentEndpoint.versesByChapter(chapterNumber: chapterNumber, query: query)
        )
    }

    func getRandomAyah(
        recitationId: Int = QuranVerseContentQuery.defaultRecitationId
    ) async throws -> RandomAyahResponse {
        let query = QuranVerseContentQuery.items(recitationId: recitationId)

        var attempt = 0
        let maxAttempts = 3
        var backoff: TimeInterval = 0.5
        
        while true {
            do {
                return try await client.send(
                    QuranContentEndpoint.randomAyah(query: query)
                )
            } catch let qf as QFError {
                switch qf {
                case .apiLimitReached(let retryAfter):
                    guard attempt < maxAttempts else { throw qf }
                    let delay = retryAfter ?? backoff
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    backoff *= 2
                    attempt += 1
                    continue
                default: throw qf
                }
            }
        }
    }

    func getTafsirByAyah(resourceId: String, ayahKey: String) async throws -> TafsirResponse {
        try await TafsirByAyahCache.shared.response(resourceId: resourceId, ayahKey: ayahKey) {
            try await client.send(
                QuranContentEndpoint.tafsirByAyah(resourceId: resourceId, ayahKey: ayahKey, query: [])
            )
        }
    }

    func getHadithsByAyah(
        ayahKey: String,
        language: String = "en",
        page: Int = 1,
        limit: Int = 4
    ) async throws -> HadithsByAyahResponse {
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

    func getRecitations() async throws -> RecitationsResponse {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "language", value: "en")
        ]
        return try await client.send(
            QuranContentEndpoint.resourcesRecitations(query: query)
        )
    }

    func getTranslations(language: String = "en") async throws -> TranslationsResponse {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "language", value: language)
        ]
        return try await client.send(
            QuranContentEndpoint.resourcesTranslations(query: query)
        )
    }

    func getVerseByKey(verseKey: String) async throws -> SingleVerseResponse {
        let query = QuranVerseContentQuery.items()
        return try await client.send(
            QuranContentEndpoint.verseByKey(verseKey: verseKey, query: query)
        )
    }
}

private actor TafsirByAyahCache {
    static let shared = TafsirByAyahCache()

    private var inflight: [String: Task<TafsirResponse, Error>] = [:]
    private var memory: [String: (TafsirResponse, Date)] = [:]
    private let ttl: TimeInterval = 600

    func response(
        resourceId: String,
        ayahKey: String,
        fetch: @Sendable @escaping () async throws -> TafsirResponse
    ) async throws -> TafsirResponse {
        let key = "\(resourceId)|\(ayahKey)"
        if let (cached, at) = memory[key], Date().timeIntervalSince(at) < ttl {
            return cached
        }
        if let task = inflight[key] {
            return try await task.value
        }
        let task = Task { try await fetch() }
        inflight[key] = task
        do {
            let value = try await task.value
            memory[key] = (value, Date())
            inflight[key] = nil
            pruneMemoryIfNeeded()
            return value
        } catch {
            inflight[key] = nil
            throw error
        }
    }

    private func pruneMemoryIfNeeded() {
        let maxEntries = 32
        guard memory.count > maxEntries else { return }
        let now = Date()
        memory = memory.filter { _, pair in
            now.timeIntervalSince(pair.1) < ttl
        }
        guard memory.count > maxEntries else { return }
        let keysByAge = memory.sorted { $0.value.1 < $1.value.1 }.map(\.key)
        let toRemove = max(0, memory.count - 24)
        for key in keysByAge.prefix(toRemove) {
            memory.removeValue(forKey: key)
        }
    }
}

private actor ChaptersCache {
    static let shared = ChaptersCache()

    private var store: [String: (chapters: [QuranChapter], fetchedAt: Date)] = [:]
    private let ttl: TimeInterval = 3600

    func get(language: String) -> [QuranChapter]? {
        guard let entry = store[language] else { return nil }
        if Date().timeIntervalSince(entry.fetchedAt) > ttl {
            store.removeValue(forKey: language)
            return nil
        }
        return entry.chapters
    }

    func set(_ chapters: [QuranChapter], language: String) {
        store[language] = (chapters, Date())
    }
}
