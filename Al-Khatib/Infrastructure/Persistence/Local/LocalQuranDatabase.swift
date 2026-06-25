//
//  LocalQuranDatabase.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

internal final class LocalQuranDatabase: Sendable {
    internal static let shared = LocalQuranDatabase()

    private let dbPath: String?

    private init() {
        // Since we are using fileSystemSynchronizedGroups, resources placed in Al-Khatib/Resources/quran
        // will be bundled as "qurannew.db" inside the main bundle.
        if let path = Bundle.main.path(forResource: "qurannew", ofType: "db") {
            self.dbPath = path
        } else if let path = Bundle.main.path(forResource: "qurannew", ofType: "db", inDirectory: "Resources/quran") {
            self.dbPath = path
        } else {
            self.dbPath = nil
        }
    }

    internal func openReadable() throws -> SQLiteConnection {
        guard let path = dbPath else {
            throw NSError(
                domain: "LocalQuranDatabase",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "qurannew.db not found in main bundle."]
            )
        }
        return try SQLiteConnection(path: path, readOnly: true)
    }

    internal func warmUp() {
        do {
            let db = try openReadable()
            let count = db.intQuery(query: "SELECT COUNT(*) FROM suras")
            assert(count == 114, "Quran database warm-up failed: expected 114 suras, got \(count)")
            db.close()
        } catch {
            print("LocalQuranDatabase warm-up error: \(error.localizedDescription)")
        }
    }
}
