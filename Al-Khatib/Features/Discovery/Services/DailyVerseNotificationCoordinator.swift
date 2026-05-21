//
//  DailyVerseNotificationCoordinator.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

@MainActor
enum DailyVerseNotificationCoordinator {
    private static let scheduler = DailyVerseNotificationScheduler()
    private static let defaults = UserDefaults.standard

    static func refreshAfterDailyAyahLoaded(_ verse: RandomAyahPayload) async {
        cache(verse: verse)
        await rescheduleFromCache()
    }

    static func refreshIfNeeded(container: AppContainer?) async {
        guard DailyVerseNotificationPreferences.isEnabled(defaults: defaults) else {
            await scheduler.cancelAll()
            return
        }

        if cacheIsFreshForToday() == false, let container {
            await fetchAndCache(container: container)
        }

        await rescheduleFromCache()
    }

    static func setEnabled(_ enabled: Bool, container: AppContainer?) async {
        defaults.set(enabled, forKey: DailyVerseNotificationPreferences.enabledKey)
        DailyVerseNotificationPreferences.notifyDidChange()

        if enabled {
            await refreshIfNeeded(container: container)
        } else {
            await scheduler.cancelAll()
        }
    }

    static func applyMorningTime(hour: Int, minute: Int, container: AppContainer?) async {
        DailyVerseNotificationPreferences.setMorningTime(hour: hour, minute: minute, defaults: defaults)
        guard DailyVerseNotificationPreferences.isEnabled(defaults: defaults) else { return }
        await rescheduleFromCache()
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

    private static func rescheduleFromCache() async {
        let enabled = DailyVerseNotificationPreferences.isEnabled(defaults: defaults)
        let time = DailyVerseNotificationPreferences.morningTime(defaults: defaults)
        let label = defaults.string(forKey: DailyVerseNotificationPreferences.cacheVerseKeyKey) ?? "Your Quran verse"
        let snippet = defaults.string(forKey: DailyVerseNotificationPreferences.cacheBodyKey) ?? ""

        await scheduler.reschedule(
            verseLabel: label,
            bodySnippet: snippet,
            hour: time.hour,
            minute: time.minute,
            enabled: enabled
        )
    }
}
