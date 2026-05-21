//
//  ReadingSessionRepository.swift
//  Al-Khatib
//

import Foundation

struct ReadingSessionRepository: Sendable {
    private let client: QFApiClient

    init(client: QFApiClient) {
        self.client = client
    }

    func fetchReadingSessions(
        first: Int? = nil,
        after: String? = nil,
        last: Int? = nil,
        before: String? = nil
    ) async throws -> ReadingSessionsPage {
        var query: [URLQueryItem] = []
        if let first {
            query.append(URLQueryItem(name: "first", value: String(clampedPageSize(first))))
        }
        if let after, after.isEmpty == false {
            query.append(URLQueryItem(name: "after", value: after))
        }
        if let last {
            query.append(URLQueryItem(name: "last", value: String(clampedPageSize(last))))
        }
        if let before, before.isEmpty == false {
            query.append(URLQueryItem(name: "before", value: before))
        }
        return try await client.send(ReadingSessionGetEndpoint(queryItems: query))
    }

    func fetchMostRecent() async throws -> ReadingSession? {
        let page = try await fetchReadingSessions(first: 1)
        return page.data?.first
    }

    func upsertReadingSession(chapterNumber: Int, verseNumber: Int) async throws {
        let body = ReadingSessionRequestBody(
            chapterNumber: chapterNumber,
            verseNumber: verseNumber
        )
        let encoder = JSONEncoder()
        let endpoint = ReadingSessionPostEndpoint(payload: try encoder.encode(body))
        let _: ReadingSessionPostEnvelope = try await client.send(endpoint)
    }

    private func clampedPageSize(_ value: Int) -> Int {
        min(max(value, 1), 20)
    }
}

private struct ReadingSessionRequestBody: Encodable, Sendable {
    let chapterNumber: Int
    let verseNumber: Int
}

private struct ReadingSessionPostEnvelope: Decodable, Sendable {
    let success: Bool?
}
