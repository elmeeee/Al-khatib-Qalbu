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
    private let reflect: ReflectRepository
    private let habits: UserHabitRepository

    init(store: ReflectionStore, reflect: ReflectRepository, habits: UserHabitRepository) {
        self.store = store
        self.reflect = reflect
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
        let profile = try await habits.fetchMyProfile()
        let created = try await reflect.createReflectionPost(
            body: r.body,
            verseKey: r.verseKey,
            authorId: profile.id,
            idempotencyKey: r.idempotencyKey
        )
        var updated = r
        updated.serverPostId = created.id
        updated.syncState = .synced
        updated.lastSyncError = nil
        updated.updatedAt = .now
        store.update(updated)
    }
}
