//
//  PrayerTrackerStore.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

internal struct PrayerDayProgress: Sendable, Identifiable {
    internal var id: String { dayKey }
    internal let dayKey: String
    internal let completedCount: Int
    internal let totalCount: Int
    internal let optionalCompletedCount: Int
    internal let optionalTotalCount: Int

    internal var fraction: Float {
        return Float(completedCount) / Float(max(totalCount, 1))
    }

    internal var isPerfectDay: Bool {
        return completedCount >= totalCount
    }
}

internal final class PrayerTrackerStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let PREFS_KEY = "alkhatib.prayer.tracker.v1"
    private let KEY_BEST_STREAK = "best_streak"
    
    private let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    internal static let TRACKED_PRAYERS: [PrayerType] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    private let qiyamStore: QiyamTrackerStore

    internal init(appGroupIdentifier: String?) {
        if let appGroupIdentifier = appGroupIdentifier,
           let shared = UserDefaults(suiteName: appGroupIdentifier) {
            self.defaults = shared
        } else {
            self.defaults = .standard
        }
        self.qiyamStore = QiyamTrackerStore(appGroupIdentifier: appGroupIdentifier)
    }

    internal func todayKey() -> String {
        return dayKeyFormatter.string(from: Date())
    }

    internal func dayKeyFor(date: Date) -> String {
        return dayKeyFormatter.string(from: date)
    }

    internal func isCompleted(prayer: PrayerType, dayKey: String) -> Bool {
        let key = prefKey(prayer: prayer, dayKey: dayKey)
        return defaults.bool(forKey: key)
    }

    internal func setCompleted(prayer: PrayerType, completed: Bool, dayKey: String) {
        let key = prefKey(prayer: prayer, dayKey: dayKey)
        defaults.set(completed, forKey: key)
        updateBestStreakIfNeeded()
    }

    internal func toggle(prayer: PrayerType, dayKey: String) -> Bool {
        let next = !isCompleted(prayer: prayer, dayKey: dayKey)
        setCompleted(prayer: prayer, completed: next, dayKey: dayKey)
        return next
    }

    internal func isOptionalCompleted(habit: OptionalWorshipHabit, dayKey: String) -> Bool {
        if habit == .qiyamulLail {
            return qiyamStore.isLogged(dayKey: dayKey)
        }
        let key = optionalPrefKey(habit: habit, dayKey: dayKey)
        return defaults.bool(forKey: key)
    }

    internal func setOptionalCompleted(habit: OptionalWorshipHabit, completed: Bool, dayKey: String) {
        if habit == .qiyamulLail {
            qiyamStore.setLogged(logged: completed, dayKey: dayKey)
            return
        }
        let key = optionalPrefKey(habit: habit, dayKey: dayKey)
        defaults.set(completed, forKey: key)
    }

    internal func toggleOptional(habit: OptionalWorshipHabit, dayKey: String) -> Bool {
        let next = !isOptionalCompleted(habit: habit, dayKey: dayKey)
        setOptionalCompleted(habit: habit, completed: next, dayKey: dayKey)
        return next
    }

    internal func completedCount(dayKey: String) -> Int {
        return Self.TRACKED_PRAYERS.count { isCompleted(prayer: $0, dayKey: dayKey) }
    }

    internal func dayProgress(dayKey: String) -> PrayerDayProgress {
        return PrayerDayProgress(
            dayKey: dayKey,
            completedCount: completedCount(dayKey: dayKey),
            totalCount: Self.TRACKED_PRAYERS.count,
            optionalCompletedCount: 0,
            optionalTotalCount: 0
        )
    }

    internal func weekProgress() -> [PrayerDayProgress] {
        var list: [PrayerDayProgress] = []
        for offset in (0...6).reversed() {
            if let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) {
                let key = dayKeyFormatter.string(from: date)
                list.append(dayProgress(dayKey: key))
            }
        }
        return list
    }

    internal func monthProgress(year: Int, month: Int) -> [PrayerDayProgress] {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let startOfMonth = Calendar.current.date(from: comps) else { return [] }
        guard let range = Calendar.current.range(of: .day, in: .month, for: startOfMonth) else { return [] }

        var list: [PrayerDayProgress] = []
        for day in 1...range.count {
            var dComps = DateComponents()
            dComps.year = year
            dComps.month = month
            dComps.day = day
            if let date = Calendar.current.date(from: dComps) {
                let key = dayKeyFormatter.string(from: date)
                list.append(dayProgress(dayKey: key))
            }
        }
        return list
    }

    internal func currentStreak() -> Int {
        let today = todayKey()
        var streak = 0
        
        var date = Date()
        for _ in 0..<400 {
            let key = dayKeyFormatter.string(from: date)
            let count = completedCount(dayKey: key)
            if count >= Self.TRACKED_PRAYERS.count {
                streak += 1
                guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
                date = prev
            } else if streak == 0 && key == today && count > 0 {
                // If it's today and we haven't completed all, but have some progress, streak is not broken yet
                guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
                date = prev
            } else {
                return streak
            }
        }
        return streak
    }

    internal func bestStreak() -> Int {
        let current = currentStreak()
        let best = defaults.integer(forKey: PREFS_KEY + "_" + KEY_BEST_STREAK)
        return max(best, current)
    }

    internal func challengeTargetDays(streak: Int) -> Int {
        if streak < 7 { return 7 }
        if streak < 30 { return 30 }
        if streak < 40 { return 40 }
        return ((streak / 10) + 1) * 10
    }

    private func updateBestStreakIfNeeded() {
        let current = currentStreak()
        let best = defaults.integer(forKey: PREFS_KEY + "_" + KEY_BEST_STREAK)
        if current > best {
            defaults.set(current, forKey: PREFS_KEY + "_" + KEY_BEST_STREAK)
        }
    }

    private func prefKey(prayer: PrayerType, dayKey: String) -> String {
        return "\(PREFS_KEY)_\(dayKey)_\(prayer.rawValue.lowercased())"
    }

    private func optionalPrefKey(habit: OptionalWorshipHabit, dayKey: String) -> String {
        return "\(PREFS_KEY)_\(dayKey)_opt_\(habit.prefKey)"
    }
}
