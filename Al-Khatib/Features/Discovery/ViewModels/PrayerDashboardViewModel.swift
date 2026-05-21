//
//  PrayerDashboardViewModel.swift
//  Al-Khatib
//
//  Created by Antigravity on 20/05/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

enum ThematicTheme: Equatable, Sendable {
    case daylight
    case night
    
    var gradientColors: [Color] {
        switch self {
        case .daylight:
            return [
                Color.Token.prayerCream,
                Color.Token.prayerCreamWarm,
                Color.Token.prayerMint
            ]
        case .night:
            return [
                Color.Token.slate900,
                Color.Token.slate800,
                Color.Token.indigoDeep
            ]
        }
    }
    
    var cardGradientColors: [Color] {
        switch self {
        case .daylight:
            return [
                Color.Token.deepEmerald,
                Color.Token.tealDark
            ]
        case .night:
            return [
                Color.Token.emeraldNight,
                Color.Token.deepEmerald
            ]
        }
    }
    
    var textColor: Color {
        return .white
    }
    
    var secondaryTextColor: Color {
        return .white.opacity(0.7)
    }
    
    var borderGradientColors: [Color] {
        return [
            Color.white.opacity(0.2),
            Color.white.opacity(0.05)
        ]
    }
    
    var mascotImageName: String {
        switch self {
        case .daylight:
            return "mascot_daylight"
        case .night:
            return "mascot_night"
        }
    }
}

struct MappedPrayerItem: Identifiable, Equatable, Sendable {
    let id: String
    let originalName: String
    let displayName: String
    let timeString: String
    let date: Date
    let isActive: Bool
}

@MainActor
final class PrayerDashboardViewModel: ObservableObject {
    @Published private(set) var activeTheme: ThematicTheme = .daylight
    @Published private(set) var mappedPrayers: [MappedPrayerItem] = []
    @Published private(set) var activePrayerDisplayName: String = ""
    @Published private(set) var activePrayerOriginalName: String = ""
    @Published private(set) var nextPrayerDisplayName: String = ""
    @Published private(set) var countdownString: String = "00:00:00"
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var cityName: String? = nil
    @Published private(set) var hijriDate: String? = nil
    
    private let controller: PrayerTimesController
    private var controllerCancellable: AnyCancellable?
    private var tickerCancellable: AnyCancellable?
    
    init(controller: PrayerTimesController) {
        self.controller = controller
        self.isLoading = controller.isLoading
        self.cityName = controller.cityName
        self.hijriDate = controller.hijriDateLabel

        self.controllerCancellable = controller.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Delay slightly to let the new properties publish
                Task {
                    self.isLoading = self.controller.isLoading
                    self.cityName = self.controller.cityName
                    self.hijriDate = self.controller.hijriDateLabel
                    self.recalculate(at: Date())
                }
            }
        
        // Ticker timer for real-time countdown & active slot transition checks
        self.tickerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                guard let self = self else { return }
                self.recalculate(at: now)
            }
        
        recalculate(at: Date())
    }
    
    private func recalculate(at now: Date) {
        let prayers = controller.dailyPrayers
        guard !prayers.isEmpty else {
            self.mappedPrayers = []
            self.countdownString = "--:--:--"
            return
        }
        
        // 1. Determine active prayer name
        let activeName = determineActivePrayerName(from: prayers, at: now)
        self.activePrayerOriginalName = activeName
        self.activePrayerDisplayName = mapToSoutheastAsianName(activeName)
        
        // 2. Determine active theme context
        self.activeTheme = determineTheme(for: activeName)
        
        // 3. Map prayers to timeline columns
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = .current
        
        self.mappedPrayers = prayers.map { entry in
            MappedPrayerItem(
                id: entry.name,
                originalName: entry.name,
                displayName: mapToSoutheastAsianName(entry.name),
                timeString: formatter.string(from: entry.date),
                date: entry.date,
                isActive: entry.name == activeName
            )
        }
        
        // 4. Determine next prayer display name
        if let next = controller.nextPrayer {
            self.nextPrayerDisplayName = mapToSoutheastAsianName(next.name)
        } else {
            self.nextPrayerDisplayName = "--"
        }
        
        if let countdown = computeCountdownString(at: now) {
            self.countdownString = countdown
        } else {
            self.countdownString = "00:00:00"
        }
    }
    
    private func determineActivePrayerName(from prayers: [PrayerEntry], at now: Date) -> String {
        let passed = prayers.filter { $0.date <= now }
        if let lastActive = passed.last {
            return lastActive.name
        } else {
            return "Isha"
        }
    }
    
    private func determineTheme(for activePrayer: String) -> ThematicTheme {
        if activePrayer == "Maghrib" || activePrayer == "Isha" {
            return .night
        } else {
            return .daylight
        }
    }
    
    private func mapToSoutheastAsianName(_ original: String) -> String {
        switch original {
        case "Fajr": return "Fajr"
        case "Sunrise": return "Sunrise"
        case "Dhuhr": return "Dhuhr"
        case "Asr": return "Asr"
        case "Maghrib": return "Maghrib"
        case "Isha": return "Isha"
        default: return original
        }
    }
    
    private func computeCountdownString(at now: Date) -> String? {
        guard let target = controller.nextPrayer?.date else { return nil }
        let seconds = Int(target.timeIntervalSince(now))
        guard seconds > 0 else { return nil }
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}
