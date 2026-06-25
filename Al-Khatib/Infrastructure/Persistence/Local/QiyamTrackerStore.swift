//
//  QiyamTrackerStore.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

internal struct QiyamMonthSnapshot: Sendable {
    internal let nightsThisMonth: Int
    internal let nightsLast7Days: Int
    internal let streak: Int
    internal let isLoggedTonight: Bool
}

internal struct QiyamDayLog: Identifiable, Sendable {
    internal var id: String { dayKey }
    internal let dayKey: String
    internal let weekdayShort: String
    internal let logged: Bool
    internal let isToday: Bool
}

internal final class QiyamTrackerStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let PREFS_KEY = "alkhatib.qiyam.tracker.v1"
    private let KEY_NIGHTS_PREFIX = "night_"
    private let KEY_STREAK = "streak"
    private let KEY_LAST_NIGHT = "last_night"
    
    private let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    internal init(appGroupIdentifier: String?) {
        if let appGroupIdentifier = appGroupIdentifier,
           let shared = UserDefaults(suiteName: appGroupIdentifier) {
            self.defaults = shared
        } else {
            self.defaults = .standard
        }
    }

    internal func todayKey() -> String {
        return dayKeyFormatter.string(from: Date())
    }

    internal func isLogged(dayKey: String) -> Bool {
        return defaults.bool(forKey: PREFS_KEY + "_" + KEY_NIGHTS_PREFIX + dayKey)
    }

    internal func setLogged(logged: Bool, dayKey: String) {
        defaults.set(logged, forKey: PREFS_KEY + "_" + KEY_NIGHTS_PREFIX + dayKey)
        if logged {
            updateStreak(today: dayKey)
        }
    }

    internal func toggleTonight() -> Bool {
        let today = todayKey()
        let next = !isLogged(dayKey: today)
        setLogged(logged: next, dayKey: today)
        return next
    }

    private func updateStreak(today: String) {
        let last = defaults.string(forKey: PREFS_KEY + "_" + KEY_LAST_NIGHT)
        var streak = defaults.integer(forKey: PREFS_KEY + "_" + KEY_STREAK)
        if last == nil || last == today {
            streak = max(streak, 1)
        } else if last == previousDay(today: today) {
            streak += 1
        } else {
            streak = 1
        }
        defaults.set(today, forKey: PREFS_KEY + "_" + KEY_LAST_NIGHT)
        defaults.set(max(streak, 1), forKey: PREFS_KEY + "_" + KEY_STREAK)
    }

    private func previousDay(today: String) -> String? {
        guard let parsed = dayKeyFormatter.date(from: today) else { return nil }
        guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: parsed) else { return nil }
        return dayKeyFormatter.string(from: prev)
    }

    internal func snapshot() -> QiyamMonthSnapshot {
        let today = todayKey()
        let monthPrefix = DateFormatter().apply {
            $0.locale = Locale(identifier: "en_US_POSIX")
            $0.dateFormat = "yyyy-MM"
        }.string(from: Date())

        var monthCount = 0
        var last7 = 0
        
        let allKeys = defaults.dictionaryRepresentation().keys
        let matchingKeys = allKeys.filter { $0.hasPrefix(PREFS_KEY + "_" + KEY_NIGHTS_PREFIX) }
        
        for key in matchingKeys {
            if defaults.bool(forKey: key) {
                let day = key.replacingOccurrences(of: PREFS_KEY + "_" + KEY_NIGHTS_PREFIX, with: "")
                if day.hasPrefix(monthPrefix) {
                    monthCount += 1
                }
                if isWithinLastDays(dayKey: day, days: 7) {
                    last7 += 1
                }
            }
        }

        return QiyamMonthSnapshot(
            nightsThisMonth: monthCount,
            nightsLast7Days: last7,
            streak: defaults.integer(forKey: PREFS_KEY + "_" + KEY_STREAK),
            isLoggedTonight: isLogged(dayKey: today)
        )
    }

    internal func last7Days() -> [QiyamDayLog] {
        let today = todayKey()
        let weekdayFormat = DateFormatter().apply {
            $0.dateFormat = "EEE"
        }
        var list: [QiyamDayLog] = []
        for offset in (0...6).reversed() {
            if let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) {
                let key = dayKeyFormatter.string(from: date)
                list.append(
                    QiyamDayLog(
                        dayKey: key,
                        weekdayShort: weekdayFormat.string(from: date),
                        logged: isLogged(dayKey: key),
                        isToday: key == today
                    )
                )
            }
        }
        return list
    }

    private func isWithinLastDays(dayKey: String, days: Int) -> Bool {
        guard let parsed = dayKeyFormatter.date(from: dayKey) else { return false }
        let now = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -days, to: now) else { return false }
        return parsed >= start && parsed <= now
    }
}

private extension DateFormatter {
    func apply(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self)
        return self
    }
}
