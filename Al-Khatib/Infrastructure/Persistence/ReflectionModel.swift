//
//  ReflectionModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct Reflection: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var body: String
    var createdAt: Date
    var updatedAt: Date
    var verseKey: String?
    var syncState: SyncState
    var serverPostId: Int?
    var idempotencyKey: String
    var lastSyncError: String?

    init(
        id: UUID = UUID(),
        body: String,
        verseKey: String?,
        syncState: SyncState = .pending
    ) {
        self.id = id
        self.body = body
        self.createdAt = .now
        self.updatedAt = .now
        self.verseKey = verseKey
        self.syncState = syncState
        self.serverPostId = nil
        self.idempotencyKey = id.uuidString
        self.lastSyncError = nil
    }
}

enum SyncState: String, Codable, CaseIterable, Sendable, Hashable, Equatable {
    case pending
    case synced
    case failed
}
