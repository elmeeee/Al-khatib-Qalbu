//
//  DailyAyahRefreshPolicy.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum DailyAyahRefreshPolicy {
    static let lastFetchKey = "discover.randomAyah.lastFetchAt"
    static let refreshInterval: TimeInterval = 60 * 60

    static func shouldRefresh(
        lastFetchTimestamp: Double,
        forceIfNoData: Bool,
        hasDetail: Bool,
        now: Date = .now
    ) -> Bool {
        if forceIfNoData, hasDetail == false { return true }
        if lastFetchTimestamp <= 0 { return true }
        let elapsed = now.timeIntervalSince1970 - lastFetchTimestamp
        return elapsed >= refreshInterval
    }

    static func markFetched(at date: Date = .now, defaults: UserDefaults = .standard) {
        defaults.set(date.timeIntervalSince1970, forKey: lastFetchKey)
    }

    static func clearLastFetch(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: lastFetchKey)
    }

    static func lastFetchTimestamp(defaults: UserDefaults = .standard) -> Double {
        defaults.double(forKey: lastFetchKey)
    }
}
