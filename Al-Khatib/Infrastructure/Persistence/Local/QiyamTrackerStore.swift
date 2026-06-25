//
//  QiyamTrackerStore.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct QiyamMonthSnapshot: Codable, Hashable, Sendable {
    let nightsThisMonth: Int
    let nightsLast7Days: Int
    let streak: Int
    let isLoggedTonight: Bool
}

struct QiyamDayLog: Codable, Hashable, Sendable {
    let dayKey: String
    let weekdayShort: String
    let logged: Bool
    let isToday: Bool
}

internal final class QiyamTrackerStore: @unchecked Sendable {
    internal static let shared = QiyamTrackerStore()
    
    private let defaults: UserDefaults
    private let PREFS_KEY = "saat_qiyam_tracker"
    private let KEY_NIGHTS_PREFIX = "night_"
    private let KEY_STREAK = "streak"
    private let KEY_LAST_NIGHT = "last_night"
    
    internal init(appGroupIdentifier: String? = nil) {
        if let appGroupIdentifier,
           let shared = UserDefaults(suiteName: appGroupIdentifier) {
            self.defaults = shared
        } else {
            self.defaults = .standard
        }
    }
    
    private var formatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }
    
    internal func todayKey() -> String {
        return formatter.string(from: Date())
    }
    
    internal func isLogged(dayKey: String? = nil) -> Bool {
        let key = dayKey ?? todayKey()
        let dict = defaults.dictionary(forKey: PREFS_KEY) ?? [:]
        return dict[KEY_NIGHTS_PREFIX + key] as? Bool ?? false
    }
    
    internal func setLogged(logged: Bool, dayKey: String? = nil) {
        let key = dayKey ?? todayKey()
        var dict = defaults.dictionary(forKey: PREFS_KEY) ?? [:]
        dict[KEY_NIGHTS_PREFIX + key] = logged
        defaults.set(dict, forKey: PREFS_KEY)
        
        if logged {
            updateStreak(today: key)
        }
    }
    
    internal func toggleTonight() -> Bool {
        let today = todayKey()
        let next = !isLogged(dayKey: today)
        setLogged(logged: next, dayKey: today)
        return next
    }
    
    private func updateStreak(today: String) {
        var dict = defaults.dictionary(forKey: PREFS_KEY) ?? [:]
        let last = dict[KEY_LAST_NIGHT] as? String
        var streak = dict[KEY_STREAK] as? Int ?? 0
        
        if last == nil {
            streak = 1
        } else if last == today {
            streak = max(streak, 1)
        } else if last == previousDay(today: today) {
            streak += 1
        } else {
            streak = 1
        }
        
        dict[KEY_LAST_NIGHT] = today
        dict[KEY_STREAK] = max(streak, 1)
        defaults.set(dict, forKey: PREFS_KEY)
    }
    
    private func previousDay(today: String) -> String? {
        guard let date = formatter.date(from: today) else { return nil }
        guard let prevDate = Calendar.current.date(byAdding: .day, value: -1, to: date) else { return nil }
        return formatter.string(from: prevDate)
    }
    
    internal func snapshot() -> QiyamMonthSnapshot {
        let dict = defaults.dictionary(forKey: PREFS_KEY) ?? [:]
        let today = todayKey()
        
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "en_US")
        monthFormatter.dateFormat = "yyyy-MM"
        let monthPrefix = monthFormatter.string(from: Date())
        
        var monthCount = 0
        var last7 = 0
        
        for (key, val) in dict {
            guard key.hasPrefix(KEY_NIGHTS_PREFIX), let logged = val as? Bool, logged else { continue }
            let day = String(key.dropFirst(KEY_NIGHTS_PREFIX.count))
            if day.hasPrefix(monthPrefix) {
                monthCount += 1
            }
            if isWithinLastDays(dayKey: day, days: 7) {
                last7 += 1
            }
        }
        
        return QiyamMonthSnapshot(
            nightsThisMonth: monthCount,
            nightsLast7Days: last7,
            streak: dict[KEY_STREAK] as? Int ?? 0,
            isLoggedTonight: isLogged(dayKey: today)
        )
    }
    
    internal func last7Days() -> [QiyamDayLog] {
        let today = todayKey()
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale.current
        weekdayFormatter.dateFormat = "EE"
        
        var list: [QiyamDayLog] = []
        let calendar = Calendar.current
        
        for offset in (0...6).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let key = formatter.string(from: date)
            list.append(
                QiyamDayLog(
                    dayKey: key,
                    weekdayShort: weekdayFormatter.string(from: date),
                    logged: isLogged(dayKey: key),
                    isToday: key == today
                )
            )
        }
        
        return list
    }
    
    private func isWithinLastDays(dayKey: String, days: Int) -> Bool {
        guard let parsed = formatter.date(from: dayKey) else { return false }
        let now = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -days, to: now) else { return false }
        
        let calendar = Calendar.current
        let startOfDayStart = calendar.startOfDay(for: start)
        let startOfParsed = calendar.startOfDay(for: parsed)
        let startOfToday = calendar.startOfDay(for: now)
        
        return startOfParsed >= startOfDayStart && startOfParsed <= startOfToday
    }
}
