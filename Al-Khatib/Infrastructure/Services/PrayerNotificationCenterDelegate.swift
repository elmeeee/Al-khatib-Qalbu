//
//  PrayerNotificationCenterDelegate.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import UserNotifications

final class PrayerNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = PrayerNotificationCenterDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.content.userInfo["openTab"] as? String == "today" {
            NotificationCenter.default.post(name: DailyVerseNotificationPreferences.openTodayTabNotification, object: nil)
        }
        completionHandler()
    }
}
