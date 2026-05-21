//
//  DailyVerseNotificationScheduler.swift
//  Al-Khatib
//

import Foundation
import OSLog
import UserNotifications

private let dailyVerseLog = Logger(subsystem: "co.kamy.Al-Khatib", category: "DailyVerseNotifications")

@MainActor
final class DailyVerseNotificationScheduler {
    enum ScheduleResult: Sendable {
        case scheduled
        case disabled
        case authorizationDenied
        case failed(String)
    }

    private let center = UNUserNotificationCenter.current()
    private let identifierPrefix = "alkhatib.dailyverse"
    private let repeatingIdentifier = "alkhatib.dailyverse.repeating"

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

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
                dailyVerseLog.error("Auth request failed: \(error.localizedDescription, privacy: .public)")
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

    /// Daily repeating reminder at the chosen local time; content refreshed whenever this runs.
    func reschedule(
        verseLabel: String,
        bodySnippet: String,
        hour: Int,
        minute: Int,
        enabled: Bool
    ) async -> ScheduleResult {
        await cancelAll()
        guard enabled else { return .disabled }

        guard await requestAuthorizationIfNeeded() else {
            dailyVerseLog.warning("Daily verse notifications: authorization denied or not granted")
            return .authorizationDenied
        }

        let title = "Your verse for today 📖"
        let body = Self.notificationBody(verseLabel: verseLabel, snippet: bodySnippet)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.timeZone = TimeZone.current

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "dailyVerse"
        content.userInfo = ["openTab": "today"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: repeatingIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            dailyVerseLog.info("Scheduled daily verse at \(hour):\(String(format: "%02d", minute), privacy: .public) — \(verseLabel, privacy: .public)")
            return .scheduled
        } catch {
            dailyVerseLog.error("Failed scheduling daily verse: \(error.localizedDescription, privacy: .public)")
            return .failed(error.localizedDescription)
        }
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
}
