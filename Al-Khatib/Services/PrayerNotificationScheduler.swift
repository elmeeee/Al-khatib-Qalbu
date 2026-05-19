//
//  PrayerNotificationScheduler.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import OSLog
import UserNotifications

private let prayerNotifLog = Logger(subsystem: "co.kamy.Al-Khatib", category: "PrayerNotifications")

private enum PrayerNotificationCopy {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH.mm"
        formatter.timeZone = .current
        return formatter
    }()

    static func title(for prayerName: String, at date: Date) -> String {
        let time = timeFormatter.string(from: date)
        return "It's time for \(prayerName) · \(time)"
    }

    static func body(for prayerName: String) -> String {
        switch prayerName {
        case "Fajr":
            return "The world is still asleep. You don't have to be."
        case "Dhuhr":
            return "Pause. Pray. Then carry on."
        case "Asr":
            return "The angels are witnessing. Don't let this one pass."
        case "Maghrib":
            return "The sun just set. This one can't wait."
        case "Isha":
            return "End your day the right way."
        default:
            return "It is now time for the \(prayerName) prayer."
        }
    }
}

struct NightDivisionEntry: Sendable {
    enum Kind: String, CaseIterable, Sendable {
        case midnight = "Midnight"
        case firstThird = "Firstthird"
        case lastThird = "Lastthird"

        var aladhanKey: String { rawValue }

        var notificationTitle: String {
            switch self {
            case .midnight: return "🌙 Midnight"
            case .firstThird: return "🌃 The Night Begins"
            case .lastThird: return "✨ The Last Third Has Begun"
            }
        }

        var notificationBody: String {
            switch self {
            case .midnight:
                return "The night is halfway through. Pray Witr before you sleep - don't let it slip away."
            case .firstThird:
                return "Rest well. The last third of the night is yours — rise for what the day can't give you."
            case .lastThird:
                return "Allah descends to the lowest heaven. The most powerful hour of the day starts now."
            }
        }
    }

    let kind: Kind
    let date: Date
}

@MainActor
final class PrayerNotificationScheduler {
    private let center = UNUserNotificationCenter.current()
    private let prayerPrefix = "alkhatib.prayer."
    private let nightPrefix = "alkhatib.night."

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                prayerNotifLog.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
                return false
            }
        @unknown default:
            return false
        }
    }

    func schedule(prayers: [PrayerEntry], nightDivisions: [NightDivisionEntry]) async {
        guard await requestAuthorizationIfNeeded() else {
            prayerNotifLog.debug("Skipping notifications — authorization not granted")
            return
        }

        let pending = await center.pendingNotificationRequests()
        let toCancel = pending.map(\.identifier).filter {
            $0.hasPrefix(prayerPrefix) || $0.hasPrefix(nightPrefix)
        }
        if toCancel.isEmpty == false {
            center.removePendingNotificationRequests(withIdentifiers: toCancel)
        }

        let now = Date()
        for prayer in prayers where prayer.date > now {
            await addNotification(
                identifier: "\(prayerPrefix)\(prayer.name).\(Int(prayer.date.timeIntervalSince1970))",
                fireDate: prayer.date,
                title: PrayerNotificationCopy.title(for: prayer.name, at: prayer.date),
                body: PrayerNotificationCopy.body(for: prayer.name)
            )
        }

        for division in nightDivisions where division.date > now {
            await addNotification(
                identifier: "\(nightPrefix).\(division.kind.rawValue).\(Int(division.date.timeIntervalSince1970))",
                fireDate: division.date,
                title: division.kind.notificationTitle,
                body: division.kind.notificationBody
            )
        }
    }

    private func addNotification(
        identifier: String,
        fireDate: Date,
        title: String,
        body: String
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            prayerNotifLog.debug("Scheduled \(identifier, privacy: .public) at \(fireDate, privacy: .public)")
        } catch {
            prayerNotifLog.error("Failed scheduling \(identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }
}
