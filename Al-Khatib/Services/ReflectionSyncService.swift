//
//  ReflectionSyncService.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//
import Foundation

actor ReflectionSyncService {
    private let store: ReflectionStore
    private let api: QFApiClient
    private let habits: UserHabitRepository

    init(store: ReflectionStore, api: QFApiClient, habits: UserHabitRepository) {
        self.store = store
        self.api = api
        self.habits = habits
    }

    /// Background drain of pending rows. Runs off the main thread via `Task` from the app layer.
    func syncPending() async {
        let pending = store.pending()
        for r in pending {
            do {
                try await syncOne(r)
            } catch QFError.missingUserSession {
                var updated = r
                updated.syncState = .pending
                updated.lastSyncError = "Waiting for sign-in token. Add user JWT in Settings to sync reflections and streaks."
                store.update(updated)
                break
            } catch {
                var updated = r
                updated.syncState = .failed
                updated.lastSyncError = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
                store.update(updated)
            }
        }
    }

    private func syncOne(_ r: Reflection) async throws {
        var refs: [QuranReference] = []
        if let vk = r.verseKey, let p = parseVerseKey(vk) {
            refs.append(QuranReference(id: vk, from: p.ayah, to: p.ayah, chapterId: p.sura))
        }
        let post = PostCreateBody(
            data: .init(
                body: r.body,
                draft: false,
                references: refs,
                global: true,
                roomPostStatus: 1
            )
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let endpoint = ReflectPostEndpoint(
            path: ReflectEndpoint.posts.path,
            bodyData: try encoder.encode(post),
            idempotencyKey: r.idempotencyKey
        )
        let res: PostCreateEnvelope = try await api.send(endpoint)
        var updated = r
        updated.serverPostId = res.data.id
        updated.syncState = .synced
        updated.lastSyncError = nil
        updated.updatedAt = .now
        store.update(updated)
        do { try await habits.logQuranActivityForToday(verses: max(1, refs.count)) } catch { }
        do { _ = try await habits.fetchQuranStreak() } catch { }
    }

    private func parseVerseKey(_ key: String) -> (sura: Int, ayah: Int)? {
        let p = key.split(separator: ":")
        guard p.count == 2, let a = Int(p[0]), let b = Int(p[1]) else { return nil }
        return (a, b)
    }
}
