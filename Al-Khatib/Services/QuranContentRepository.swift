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

    init(client: QFApiClient) {
        self.client = client
    }

    func getRandomAyah() async throws -> RandomAyahResponse {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "translations", value: "85"),
            URLQueryItem(name: "audio", value: "6"),
            URLQueryItem(name: "fields", value: "text_uthmani_tajweed"),
            URLQueryItem(name: "translation_fields", value: "resource_name")
        ]

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

    func getRecitations() async throws -> RecitationsResponse {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "language", value: "en")
        ]
        return try await client.send(
            QuranContentEndpoint.resourcesRecitations(query: query)
        )
    }
}
