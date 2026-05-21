//
//  DailyVerseNotificationScheduler.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import OSLog
import UserNotifications

private let dailyVerseLog = Logger(subsystem: "co.kamy.Al-Khatib", category: "DailyVerseNotifications")

@MainActor
final class DailyVerseNotificationScheduler {
    private let center = UNUserNotificationCenter.current()
    private let identifierPrefix = "alkhatib.dailyverse"
    private let daysAhead = 14

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

    func cancelAll() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
        guard ids.isEmpty == false else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func reschedule(
        verseLabel: String,
        bodySnippet: String,
        hour: Int,
        minute: Int,
        enabled: Bool
    ) async {
        await cancelAll()
        guard enabled else { return }
        guard await requestAuthorizationIfNeeded() else { return }

        let title = "Your verse for today 📖"
        let body = Self.notificationBody(verseLabel: verseLabel, snippet: bodySnippet)
        let now = Date()
        let calendar = Calendar.current

        for dayOffset in 0..<daysAhead {
            guard let fireDate = Self.morningDate(
                dayOffset: dayOffset,
                hour: hour,
                minute: minute,
                from: now,
                calendar: calendar
            ), fireDate > now else {
                continue
            }

            let dayKey = DailyVerseNotificationPreferences.todayKey(
                calendar: calendar,
                date: fireDate
            )
            let id = "\(identifierPrefix).\(dayKey).\(hour).\(minute)"
            await addNotification(identifier: id, fireDate: fireDate, title: title, body: body)
        }
    }

    private static func morningDate(
        dayOffset: Int,
        hour: Int,
        minute: Int,
        from now: Date,
        calendar: Calendar
    ) -> Date? {
        guard let baseDay = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) else {
            return nil
        }
        var comps = calendar.dateComponents([.year, .month, .day], from: baseDay)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return calendar.date(from: comps)
    }

    private static func notificationBody(verseLabel: String, snippet: String) -> String {
        let trimmedSnippet = snippet.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedSnippet.isEmpty {
            return "Today: \(verseLabel). Open Al-Khatib to listen, read, and reflect."
        }
        let short = trimmedSnippet.count > 140
            ? String(trimmedSnippet.prefix(137)) + "…"
            : trimmedSnippet
        return "Today: \(verseLabel) — \"\(short)\""
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
        content.categoryIdentifier = "dailyVerse"
        content.userInfo = ["openTab": "today"]

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
            dailyVerseLog.error("Failed scheduling \(identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }
}

private extension DailyVerseNotificationPreferences {
    static func todayKey(calendar: Calendar, date: Date) -> String {
        let fmt = DateFormatter()
        fmt.calendar = calendar
        fmt.timeZone = calendar.timeZone
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}
