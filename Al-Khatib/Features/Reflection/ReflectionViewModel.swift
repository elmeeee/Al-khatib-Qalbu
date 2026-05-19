//
//  ReflectionViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReflectionViewModel {
    var text: String = ""
    var verseKey: String = ""
    var lastError: String?
    var lastSaved: String?
    var isSyncing = false

    private let container: AppContainer
    private let store: ReflectionStore

    init(container: AppContainer) {
        self.container = container
        self.store = container.reflectionStore
    }

    func save() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.isEmpty == false else {
            lastError = "Write something from the heart (minimum 6 characters for the Post API when syncing)."
            return
        }
        let vk: String? = {
            let s = verseKey.trimmingCharacters(in: .whitespacesAndNewlines)
            return s.isEmpty ? nil : s
        }()
        let r = Reflection(
            body: t,
            verseKey: vk,
            syncState: .pending
        )
        store.append(r)
        lastError = nil
        lastSaved = "Saved locally. Sync will continue automatically in background."
        text = ""
        verseKey = ""
        Task { await syncNow() }
    }

    func syncNow() async {
        isSyncing = true
        await self.container.makeSyncService().syncPending()
        isSyncing = false
    }

    func saveAndSync() async -> String {
        save()
        await syncNow()
        if store.hasPending() {
            return "Saved offline. Will sync when online."
        }
        return "+1 Day Added to Streak!"
    }
}
