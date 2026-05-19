//
//  ReflectionStore.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

final class ReflectionStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let storageKey = "alkhatib.reflection.journal.v1"
    private let lock = NSLock()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    init(appGroupIdentifier: String) {
        if let shared = UserDefaults(suiteName: appGroupIdentifier) {
            self.defaults = shared
        } else {
            self.defaults = .standard
        }
    }

    func loadAll() -> [Reflection] {
        lock.lock(); defer { lock.unlock() }
        return loadAllUnlocked()
    }

    func append(_ item: Reflection) {
        lock.lock(); defer { lock.unlock() }
        var all = loadAllUnlocked()
        all.append(item)
        saveAllUnlocked(all)
    }

    func update(_ item: Reflection) {
        lock.lock(); defer { lock.unlock() }
        var all = loadAllUnlocked()
        if let idx = all.firstIndex(where: { $0.id == item.id }) {
            all[idx] = item
        } else {
            all.append(item)
        }
        saveAllUnlocked(all)
    }

    func pending() -> [Reflection] {
        loadAll().filter { $0.syncState == .pending || $0.syncState == .failed }
    }

    func hasPending() -> Bool {
        loadAll().contains { $0.syncState == .pending }
    }

    private func loadAllUnlocked() -> [Reflection] {
        guard let data = defaults.data(forKey: storageKey) else { return [] }
        return (try? decoder.decode([Reflection].self, from: data)) ?? []
    }

    private func saveAllUnlocked(_ items: [Reflection]) {
        guard let data = try? encoder.encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
