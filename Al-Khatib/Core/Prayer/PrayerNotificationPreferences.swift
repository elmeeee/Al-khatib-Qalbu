//
//  PrayerNotificationPreferences.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum PrayerNotificationPreferences {
    static let adzanKey = "adzanNotificationsEnabled"
    static let imsakKey = "imsakNotificationsEnabled"
    static let midnightKey = "midnightNotificationsEnabled"
    static let firstThirdKey = "firstThirdNotificationsEnabled"
    static let tahajudKey = "tahajudNotificationsEnabled"

    static let didChangeNotification = Notification.Name("prayerNotificationPreferencesDidChange")

    struct ScheduleOptions: Sendable {
        var adzanEnabled: Bool
        var imsakEnabled: Bool
        var midnightEnabled: Bool
        var firstThirdEnabled: Bool
        var lastThirdEnabled: Bool
    }

    static func scheduleOptions(defaults: UserDefaults = .standard) -> ScheduleOptions {
        ScheduleOptions(
            adzanEnabled: bool(forKey: adzanKey, default: true, defaults: defaults),
            imsakEnabled: bool(forKey: imsakKey, default: true, defaults: defaults),
            midnightEnabled: bool(forKey: midnightKey, default: true, defaults: defaults),
            firstThirdEnabled: bool(forKey: firstThirdKey, default: true, defaults: defaults),
            lastThirdEnabled: bool(forKey: tahajudKey, default: true, defaults: defaults)
        )
    }

    static func notifyDidChange() {
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    private static func bool(forKey key: String, default defaultValue: Bool, defaults: UserDefaults) -> Bool {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }
}
