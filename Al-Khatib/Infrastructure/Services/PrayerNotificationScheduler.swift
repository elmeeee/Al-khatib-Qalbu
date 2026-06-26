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
        case "Imsak":
            return "Prepare for your fast. The dawn is near."
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
    private let prayerPrefix = "alkhatib.prayer"
    private let nightPrefix = "alkhatib.night"

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
                return false
            }
        @unknown default:
            return false
        }
    }

    func schedule(
        prayers: [PrayerEntry],
        imsakEntry: PrayerEntry?,
        nightDivisions: [NightDivisionEntry],
        options: PrayerNotificationPreferences.ScheduleOptions
    ) async {
        guard await requestAuthorizationIfNeeded() else {
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
        let calendar = Calendar.current
        var scheduledCount = 0

        if options.adzanEnabled {
            for prayer in prayers {
                for fireDate in Self.upcomingOccurrences(of: prayer.date, from: now, calendar: calendar) {
                    let id = "\(prayerPrefix).\(prayer.name).\(Int(fireDate.timeIntervalSince1970))"
                    await addNotification(
                        identifier: id,
                        fireDate: fireDate,
                        title: PrayerNotificationCopy.title(for: prayer.name, at: fireDate),
                        body: PrayerNotificationCopy.body(for: prayer.name)
                    )
                    scheduledCount += 1
                }
            }
        }

        if options.imsakEnabled, let imsak = imsakEntry {
            for fireDate in Self.upcomingOccurrences(of: imsak.date, from: now, calendar: calendar) {
                let id = "\(prayerPrefix).Imsak.\(Int(fireDate.timeIntervalSince1970))"
                await addNotification(
                    identifier: id,
                    fireDate: fireDate,
                    title: PrayerNotificationCopy.title(for: "Imsak", at: fireDate),
                    body: PrayerNotificationCopy.body(for: "Imsak")
                )
                scheduledCount += 1
            }
        }

        for division in nightDivisions {
            let enabled: Bool = switch division.kind {
            case .midnight: options.midnightEnabled
            case .firstThird: options.firstThirdEnabled
            case .lastThird: options.lastThirdEnabled
            }
            guard enabled else { continue }

            for fireDate in Self.upcomingOccurrences(of: division.date, from: now, calendar: calendar) {
                let id = "\(nightPrefix).\(division.kind.rawValue).\(Int(fireDate.timeIntervalSince1970))"
                await addNotification(
                    identifier: id,
                    fireDate: fireDate,
                    title: division.kind.notificationTitle,
                    body: division.kind.notificationBody
                )
                scheduledCount += 1
            }
        }
    }

    private static func upcomingOccurrences(of date: Date, from now: Date, calendar: Calendar) -> [Date] {
        if date > now {
            return [date]
        }
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date), tomorrow > now else {
            return []
        }
        return [tomorrow]
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
        let soundName = UserDefaults.standard.string(forKey: "selected_adhan_sound") ?? "default"
        if soundName == "default" {
            content.sound = .default
        } else {
            if Bundle.main.url(forResource: soundName, withExtension: "mp3") != nil {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(soundName).mp3"))
            } else if Bundle.main.url(forResource: soundName, withExtension: "mp3", subdirectory: "adhan") != nil {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "adhan/\(soundName).mp3"))
            } else {
                content.sound = .default
            }
        }

        var comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        comps.calendar = Calendar.current
        comps.timeZone = TimeZone.current
        comps.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            prayerNotifLog.error("Failed scheduling \(identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }
}
