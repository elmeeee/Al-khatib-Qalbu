//
//  APICache.swift
//  Al-Khatib
//
//  Created by Elmee on 19/05/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation


enum APICache {
    #if DEBUG
    private nonisolated static let profileTTL: TimeInterval = 30
    private nonisolated static let reflectFeedTTL: TimeInterval = 30
    #else
    private nonisolated static let profileTTL: TimeInterval = 300
    private nonisolated static let reflectFeedTTL: TimeInterval = 45
    #endif

    actor Profile {
        static let shared = Profile()

        private var value: UserProfilePayload?
        private var fetchedAt: Date?

        func cached() -> UserProfilePayload? {
            guard APICache.profileTTL > 0,
                  let value,
                  let fetchedAt,
                  Date().timeIntervalSince(fetchedAt) < APICache.profileTTL else {
                return nil
            }
            return value
        }

        func isFresh() -> Bool {
            cached() != nil
        }

        func store(_ profile: UserProfilePayload) {
            value = profile
            fetchedAt = .now
        }

        func clear() {
            value = nil
            fetchedAt = nil
        }
    }

    actor ReflectFeed {
        static let shared = ReflectFeed()

        private struct Entry {
            let envelope: ReflectFeedEnvelope
            let limit: Int
            let fetchedAt: Date
        }

        private var feed: Entry?
        private var myPosts: Entry?

        func cachedFeed(limit: Int) -> ReflectFeedEnvelope? {
            cached(entry: feed, limit: limit)
        }

        func cachedMyPosts(limit: Int) -> ReflectFeedEnvelope? {
            cached(entry: myPosts, limit: limit)
        }

        func storeFeed(_ envelope: ReflectFeedEnvelope, limit: Int) {
            feed = Entry(envelope: envelope, limit: limit, fetchedAt: .now)
        }

        func storeMyPosts(_ envelope: ReflectFeedEnvelope, limit: Int) {
            myPosts = Entry(envelope: envelope, limit: limit, fetchedAt: .now)
        }

        func clear() {
            feed = nil
            myPosts = nil
        }

        private func cached(entry: Entry?, limit: Int) -> ReflectFeedEnvelope? {
            guard APICache.reflectFeedTTL > 0,
                  let entry,
                  entry.limit == limit,
                  Date().timeIntervalSince(entry.fetchedAt) < APICache.reflectFeedTTL else {
                return nil
            }
            return entry.envelope
        }
    }

    static func clearAll() async {
        await Profile.shared.clear()
        await ReflectFeed.shared.clear()
    }
}
