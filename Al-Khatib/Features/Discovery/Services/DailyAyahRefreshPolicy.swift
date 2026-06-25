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
    static let lastPeriodKey = "discover.randomAyah.lastFetchPeriod"

    static func currentPeriod(for date: Date = .now, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        let period: String
        if hour >= 4 && hour < 12 {
            period = "pagi"
        } else if hour >= 12 && hour < 18 {
            period = "siang"
        } else {
            period = "malam"
        }
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        return "\(year)-\(dayOfYear)-\(period)"
    }

    static func currentPeriodIndex(for date: Date = .now, calendar: Calendar = .current) -> Int {
        let hour = calendar.component(.hour, from: date)
        if hour >= 4 && hour < 12 {
            return 0
        } else if hour >= 12 && hour < 18 {
            return 1
        } else {
            return 2
        }
    }

    static func shouldRefresh(
        lastFetchTimestamp: Double,
        forceIfNoData: Bool,
        hasDetail: Bool,
        now: Date = .now,
        defaults: UserDefaults = .standard
    ) -> Bool {
        if forceIfNoData, hasDetail == false { return true }
        let current = currentPeriod(for: now)
        let last = defaults.string(forKey: lastPeriodKey) ?? ""
        return current != last
    }

    static func markFetched(at date: Date = .now, defaults: UserDefaults = .standard) {
        defaults.set(date.timeIntervalSince1970, forKey: lastFetchKey)
        defaults.set(currentPeriod(for: date), forKey: lastPeriodKey)
    }

    static func clearLastFetch(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: lastFetchKey)
        defaults.removeObject(forKey: lastPeriodKey)
    }

    static func lastFetchTimestamp(defaults: UserDefaults = .standard) -> Double {
        defaults.double(forKey: lastFetchKey)
    }
}
