//
//  QuranContentRepository.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

/// Shared Content API query params for verse payloads (random ayah, by chapter, etc.).
private enum QuranVerseContentQuery {
    static let language = "en"
    static let translations = "85"
    static let audio = "6"
    static let fields = "text_uthmani_tajweed"
    static let translationFields = "resource_name"

    static func items(page: Int? = nil, perPage: Int? = nil) -> [URLQueryItem] {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "translations", value: translations),
            URLQueryItem(name: "audio", value: audio),
            URLQueryItem(name: "fields", value: fields),
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
        let query = [URLQueryItem(name: "language", value: language)]
        let response: ChaptersResponse = try await client.send(
            QuranContentEndpoint.chapters(query: query)
        )
        return response.chapters.sorted { $0.id < $1.id }
    }

    func getVersesByChapter(
        chapterNumber: Int,
        page: Int = 1,
        perPage: Int = 50
    ) async throws -> VersesByChapterResponse {
        let query = QuranVerseContentQuery.items(page: page, perPage: perPage)
        return try await client.send(
            QuranContentEndpoint.versesByChapter(chapterNumber: chapterNumber, query: query)
        )
    }

    func getRandomAyah() async throws -> RandomAyahResponse {
        let query = QuranVerseContentQuery.items()

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
        return try await client.send(
            QuranContentEndpoint.tafsirByAyah(resourceId: resourceId, ayahKey: ayahKey, query: [])
        )
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
}
