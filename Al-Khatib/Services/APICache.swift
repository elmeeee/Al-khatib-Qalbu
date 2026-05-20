//
//  APICache.swift
//  Al-Khatib
//
//  Created by Elmee on 19/05/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum APICache {
    actor Profile {
        static let shared = Profile()

        private var value: UserProfilePayload?
        private var fetchedAt: Date?
        private let ttl: TimeInterval = 300

        func cached() -> UserProfilePayload? {
            guard let value, let fetchedAt, Date().timeIntervalSince(fetchedAt) < ttl else {
                return nil
            }
            return value
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
        private let ttl: TimeInterval = 45

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
            guard let entry, entry.limit == limit, Date().timeIntervalSince(entry.fetchedAt) < ttl else {
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
