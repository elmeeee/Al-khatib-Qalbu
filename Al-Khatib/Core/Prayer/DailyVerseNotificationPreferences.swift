//
//  DailyVerseNotificationPreferences.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum DailyVerseNotificationPreferences {
    static let enabledKey = "dailyVerseNotificationsEnabled"
    static let hourKey = "dailyVerseNotificationHour"
    static let minuteKey = "dailyVerseNotificationMinute"
    static let cacheDayKey = "dailyVerseNotification.cacheDay"
    static let cacheVerseKeyKey = "dailyVerseNotification.cacheVerseKey"
    static let cacheBodyKey = "dailyVerseNotification.cacheBody"

    static let didChangeNotification = Notification.Name("dailyVerseNotificationPreferencesDidChange")
    static let openTodayTabNotification = Notification.Name("dailyVerseNotificationOpenToday")

    static let defaultHour = 7
    static let defaultMinute = 0

    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        guard defaults.object(forKey: enabledKey) != nil else { return true }
        return defaults.bool(forKey: enabledKey)
    }

    static func morningTime(defaults: UserDefaults = .standard) -> (hour: Int, minute: Int) {
        let hour = defaults.object(forKey: hourKey) != nil
            ? defaults.integer(forKey: hourKey)
            : defaultHour
        let minute = defaults.object(forKey: minuteKey) != nil
            ? defaults.integer(forKey: minuteKey)
            : defaultMinute
        return (max(0, min(23, hour)), max(0, min(59, minute)))
    }

    static func setMorningTime(hour: Int, minute: Int, defaults: UserDefaults = .standard) {
        let clampedHour = max(0, min(23, hour))
        let clampedMinute = max(0, min(59, minute))
        defaults.set(clampedHour, forKey: hourKey)
        defaults.set(clampedMinute, forKey: minuteKey)
        notifyDidChange()
    }

    static func formattedMorningTime(
        hour: Int? = nil,
        minute: Int? = nil,
        defaults: UserDefaults = .standard
    ) -> String {
        let time = morningTime(defaults: defaults)
        let h = hour ?? time.hour
        let m = minute ?? time.minute
        var components = DateComponents()
        components.hour = h
        components.minute = m
        guard let date = Calendar.current.date(from: components) else {
            return String(format: "%d:%02d", h, m)
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    static func notifyDidChange() {
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    static func todayKey(calendar: Calendar = .current) -> String {
        let fmt = DateFormatter()
        fmt.calendar = calendar
        fmt.timeZone = calendar.timeZone
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
}
