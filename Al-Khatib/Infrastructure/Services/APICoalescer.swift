//
//  APICoalescer.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum APICoalescer {
    actor Gate<T: Sendable> {
        private var inFlight: Task<T, Error>?

        func run(_ operation: @Sendable @escaping () async throws -> T) async throws -> T {
            if let inFlight {
                return try await inFlight.value
            }
            let task = Task {
                try await operation()
            }
            inFlight = task
            defer { inFlight = nil }
            return try await task.value
        }
    }

    static let profile = Gate<UserProfilePayload>()
    static let reflectFeed = Gate<ReflectFeedEnvelope>()
    static let reflectMyPosts = Gate<ReflectFeedEnvelope>()
}
