//
//  DailyVerseNotificationCoordinator.swift
//  Al-Khatib
//

import Foundation
import UserNotifications

@MainActor
enum DailyVerseNotificationCoordinator {
    private static let scheduler = DailyVerseNotificationScheduler()
    private static let defaults = UserDefaults.standard

    @discardableResult
    static func refreshAfterDailyAyahLoaded(_ verse: RandomAyahPayload) async -> DailyVerseNotificationScheduler.ScheduleResult {
        cache(verse: verse)
        return await rescheduleFromCache()
    }

    @discardableResult
    static func refreshIfNeeded(container: AppContainer?) async -> DailyVerseNotificationScheduler.ScheduleResult {
        guard DailyVerseNotificationPreferences.isEnabled(defaults: defaults) else {
            await scheduler.cancelAll()
            return .disabled
        }

        if cacheIsFreshForToday() == false, let container {
            await fetchAndCache(container: container)
        }

        return await rescheduleFromCache()
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool, container: AppContainer?) async -> DailyVerseNotificationScheduler.ScheduleResult {
        defaults.set(enabled, forKey: DailyVerseNotificationPreferences.enabledKey)
        DailyVerseNotificationPreferences.notifyDidChange()

        if enabled {
            return await refreshIfNeeded(container: container)
        }
        await scheduler.cancelAll()
        return .disabled
    }

    @discardableResult
    static func applyMorningTime(
        hour: Int,
        minute: Int,
        container: AppContainer?
    ) async -> DailyVerseNotificationScheduler.ScheduleResult {
        DailyVerseNotificationPreferences.setMorningTime(hour: hour, minute: minute, defaults: defaults)
        guard DailyVerseNotificationPreferences.isEnabled(defaults: defaults) else {
            return .disabled
        }

        if cacheIsFreshForToday() == false, let container {
            await fetchAndCache(container: container)
        }

        return await rescheduleFromCache()
    }

    static func isAuthorizationDenied() async -> Bool {
        await scheduler.authorizationStatus() == .denied
    }

    private static func cacheIsFreshForToday() -> Bool {
        let day = defaults.string(forKey: DailyVerseNotificationPreferences.cacheDayKey)
        let key = defaults.string(forKey: DailyVerseNotificationPreferences.cacheVerseKeyKey)
        return day == DailyVerseNotificationPreferences.todayKey() && key?.isEmpty == false
    }

    private static func cache(verse: RandomAyahPayload) {
        let label = verse.verseKey.map { VerseKeyFormat.humanLabel(for: $0) } ?? "Quran"
        let snippet = verse.translations?.first?.text?
            .strippingHTMLToPlainText()
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        defaults.set(DailyVerseNotificationPreferences.todayKey(), forKey: DailyVerseNotificationPreferences.cacheDayKey)
        defaults.set(label, forKey: DailyVerseNotificationPreferences.cacheVerseKeyKey)
        defaults.set(snippet, forKey: DailyVerseNotificationPreferences.cacheBodyKey)
    }

    private static func fetchAndCache(container: AppContainer) async {
        guard let response = try? await container.content.getRandomAyah(),
              let verse = response.verse else {
            return
        }
        cache(verse: verse)
    }

    @discardableResult
    private static func rescheduleFromCache() async -> DailyVerseNotificationScheduler.ScheduleResult {
        let enabled = DailyVerseNotificationPreferences.isEnabled(defaults: defaults)
        let time = DailyVerseNotificationPreferences.morningTime(defaults: defaults)
        let label = defaults.string(forKey: DailyVerseNotificationPreferences.cacheVerseKeyKey) ?? "Your Quran verse"
        let snippet = defaults.string(forKey: DailyVerseNotificationPreferences.cacheBodyKey) ?? ""

        return await scheduler.reschedule(
            verseLabel: label,
            bodySnippet: snippet,
            hour: time.hour,
            minute: time.minute,
            enabled: enabled
        )
    }
}
