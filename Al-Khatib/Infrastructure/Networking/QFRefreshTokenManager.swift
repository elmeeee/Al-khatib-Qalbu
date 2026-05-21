//
//  QFRefreshTokenManager.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

actor QFRefreshTokenManager {
    private var ongoingRefreshTask: Task<Void, Error>?

    func refreshIfNeeded(using action: @escaping @Sendable () async throws -> Void) async throws {
        if let task = ongoingRefreshTask {
            return try await task.value
        }

        let task = Task {
            try await action()
        }
        ongoingRefreshTask = task
        defer { ongoingRefreshTask = nil }
        try await task.value
    }
}
