//
//  ReflectRepository.swift
//  Al-Khatib
//
//  Created by Elmee on 19/05/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct ReflectRepository: Sendable {
    private let client: QFApiClient
    private let habits: UserHabitRepository

    init(client: QFApiClient, habits: UserHabitRepository) {
        self.client = client
        self.habits = habits
    }

    func fetchFeed(page: Int = 1, limit: Int = 12, force: Bool = false) async throws -> ReflectFeedEnvelope {
        if page == 1, force == false, let cached = await APICache.ReflectFeed.shared.cachedFeed(limit: limit) {
            return cached
        }
        let envelope: ReflectFeedEnvelope = try await client.send(ReflectFeedEndpoint(page: page, limit: limit))
        if page == 1 {
            await APICache.ReflectFeed.shared.storeFeed(envelope, limit: limit)
        }
        return envelope
    }

    func fetchMyPosts(page: Int = 1, limit: Int = 12, force: Bool = false) async throws -> ReflectFeedEnvelope {
        if page == 1, force == false, let cached = await APICache.ReflectFeed.shared.cachedMyPosts(limit: limit) {
            return cached
        }
        let envelope: ReflectFeedEnvelope = try await client.send(ReflectMyPostsEndpoint(page: page, limit: limit))
        if page == 1 {
            await APICache.ReflectFeed.shared.storeMyPosts(envelope, limit: limit)
        }
        return envelope
    }

    func toggleLike(postId: String) async throws -> Bool {
        let response: ReflectToggleLikeResponse = try await client.send(
            ReflectToggleLikeEndpoint(postId: postId)
        )
        return response.liked
    }

    @discardableResult
    func createReflectionPost(
        body: String,
        verseKey: String?,
        authorId: String,
        draft: Bool = false,
        idempotencyKey: String? = nil
    ) async throws -> UserPost {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 6 else {
            throw QFError.parsingError("Reflection must be at least 6 characters.")
        }
        guard authorId.isEmpty == false else {
            throw QFError.parsingError("Missing author id. Sign in again.")
        }

        var refs: [PostCreateReference] = []
        if let verseKey, let parsed = Self.parseVerseKey(verseKey) {
            refs.append(
                PostCreateReference(
                    chapterId: parsed.sura,
                    from: parsed.ayah,
                    to: parsed.ayah
                )
            )
        }

        let request = PostCreateRequest(
            post: .init(
                body: trimmed,
                draft: draft,
                references: refs,
                mentions: [],
                roomPostStatus: 1,
                roomId: 0,
                postAsAuthorId: authorId,
                publishedAt: Self.iso8601Now()
            )
        )
        let bodyData = try ReflectAPIJSON.encode(request)
        let endpoint = ReflectPostEndpoint(
            path: AppEndpoints.Reflect.posts,
            bodyData: bodyData,
            idempotencyKey: idempotencyKey
        )
        async let postEnvelope: PostCreateEnvelope = client.send(endpoint)
        if refs.isEmpty == false {
            Task.detached(priority: .background) {
                try? await self.habits.logQuranActivityForToday(verses: refs.count)
            }
        }
        let envelope = try await postEnvelope

        guard let created = envelope.createdPost else {
            throw QFError.parsingError("create post response missing post payload")
        }
        await APICache.ReflectFeed.shared.clear()
        return created
    }

    func createPostFromShare(
        body: String,
        verseKey: String?,
        authorId: String,
        languageId: Int?
    ) async throws -> UserPost {
        _ = languageId
        return try await createReflectionPost(
            body: body,
            verseKey: verseKey,
            authorId: authorId
        )
    }

    static func parseVerseKey(_ key: String) -> (sura: Int, ayah: Int)? {
        let parts = key.split(separator: ":")
        guard parts.count == 2,
              let sura = Int(parts[0]),
              let ayah = Int(parts[1]),
              sura >= 1,
              ayah >= 1 else {
            return nil
        }
        return (sura, ayah)
    }

    private static func iso8601Now() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}

enum ReflectAPIJSON {
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }
}
