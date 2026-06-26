//
//  PrayerTrackerViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Combine
import Foundation

internal struct OptionalHabitUiItem: Identifiable, Sendable {
    internal var id: String { habit.rawValue }
    internal let habit: OptionalWorshipHabit
    internal let label: String
    internal let completed: Bool
    internal let applicableToday: Bool
}

internal struct PrayerTrackerUiState: Sendable {
    internal var todayProgress: PrayerDayProgress = PrayerDayProgress(dayKey: "", completedCount: 0, totalCount: 5, optionalCompletedCount: 0, optionalTotalCount: 0)
    internal var weekProgress: [PrayerDayProgress] = []
    internal var monthPreview: [PrayerDayProgress] = []
    internal var streak: Int = 0
    internal var bestStreak: Int = 0
    internal var challengeTarget: Int = 7
    internal var completedPrayers: Set<PrayerType> = []
    internal var optionalHabits: [OptionalHabitUiItem] = []
    internal var availablePrayers: Set<PrayerType> = []
}

@MainActor
internal final class PrayerTrackerViewModel: ObservableObject {
    @Published internal var state = PrayerTrackerUiState()
    @Published internal var toastMessage: String?

    private let store: PrayerTrackerStore
    private let controller: PrayerTimesController
    private var controllerCancellable: AnyCancellable?
    private var languageCancellable: AnyCancellable?

    internal init(appGroupIdentifier: String?, controller: PrayerTimesController) {
        self.store = PrayerTrackerStore(appGroupIdentifier: appGroupIdentifier)
        self.controller = controller

        self.controllerCancellable = controller.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
        
        self.languageCancellable = NotificationCenter.default.publisher(for: .appLanguageDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
        
        refresh()
    }

    internal func refresh() {
        let today = store.todayKey()
        let completed = PrayerTrackerStore.TRACKED_PRAYERS.filter {
            store.isCompleted(prayer: $0, dayKey: today)
        }
        let streak = store.currentStreak()

        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let month = cal.component(.month, from: Date())

        let available = availablePrayersList()

        self.state = PrayerTrackerUiState(
            todayProgress: store.dayProgress(dayKey: today),
            weekProgress: store.weekProgress(),
            monthPreview: store.monthProgress(year: year, month: month),
            streak: streak,
            bestStreak: store.bestStreak(),
            challengeTarget: store.challengeTargetDays(streak: streak),
            completedPrayers: Set(completed),
            optionalHabits: buildOptionalHabits(today: today),
            availablePrayers: Set(available)
        )
    }

    internal func togglePrayer(_ prayer: PrayerType) {
        let completed = state.completedPrayers.contains(prayer)
        // Check availability
        if !completed && !availablePrayersList().contains(prayer) {
            // Cannot mark future prayer
            return
        }

        let today = store.todayKey()
        _ = store.toggle(prayer: prayer, dayKey: today)
        
        let nowCompleted = store.isCompleted(prayer: prayer, dayKey: today)
        if nowCompleted {
            let prayerName = AppLanguageManager.shared.localize("prayer_" + prayer.rawValue.lowercased())
            self.toastMessage = String(format: AppLanguageManager.shared.localize("toast_marked_completed"), prayerName)
        }
        refresh()
    }

    internal func toggleOptionalHabit(_ habit: OptionalWorshipHabit) {
        let today = store.todayKey()
        _ = store.toggleOptional(habit: habit, dayKey: today)
        refresh()
    }

    private func availablePrayersList() -> [PrayerType] {
        let now = Date()
        // Map dailyPrayers from PrayerTimesController
        var list: [PrayerType] = []
        for entry in controller.dailyPrayers {
            if let type = PrayerType.from(aladhanKey: entry.name) {
                if now >= entry.date {
                    list.append(type)
                }
            }
        }
        // If dailyPrayers is empty, allow checking based on time or fallback to all
        if controller.dailyPrayers.isEmpty {
            return [.fajr, .dhuhr, .asr, .maghrib, .isha]
        }
        return list
    }

    private func buildOptionalHabits(today: String) -> [OptionalHabitUiItem] {
        // In iOS, we enable Qiyamul Lail by default, and others are optional
        // For Monday/Thursday fasting: check day of week (2 is Monday, 5 is Thursday in Calendar)
        let weekday = Calendar.current.component(.weekday, from: Date())
        let isMonThu = (weekday == 2 || weekday == 5)

        // For Ayyamul Bidh (13, 14, 15 of Hijri month).
        // Since we have hijriDateLabel (e.g. "13 Shaban 1445"), let's parse the day number
        var isAyyamulBidh = false
        if let hijri = controller.hijriDateLabel {
            let num = hijri.split(separator: " ").first.flatMap { Int($0) }
            if let dayVal = num, (13...15).contains(dayVal) {
                isAyyamulBidh = true
            }
        }

        return OptionalWorshipHabit.allCases.compactMap { habit in
            let applicable = (habit == .qiyamulLail) ? true :
                             (habit == .mondayThursdayFast ? isMonThu : isAyyamulBidh)
            
            guard applicable else { return nil }

            let label = (habit == .qiyamulLail) ? AppLanguageManager.shared.localize("habit_qiyamul_lail") :
                        (habit == .mondayThursdayFast ? AppLanguageManager.shared.localize("habit_monday_thursday_fast") : AppLanguageManager.shared.localize("habit_ayyamul_bidh_fast"))

            return OptionalHabitUiItem(
                habit: habit,
                label: label,
                completed: store.isOptionalCompleted(habit: habit, dayKey: today),
                applicableToday: true
            )
        }
    }
}
