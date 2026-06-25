//
//  Al_KhatibApp.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI
import ProwlKit
import UserNotifications

@main
struct Al_KhatibApp: App {
    private let appContainer: AppContainer

    init() {
        Prowl.start()
        UNUserNotificationCenter.current().delegate = PrayerNotificationCenterDelegate.shared
        self.appContainer = AppContainer()
        _ = AlKhatibTypography.verseArabicHTMLBaseDirectory()
        Task { @MainActor in
            _ = AlKhatibTypography.quranArabicUIFont(size: 24)
            if DailyVerseNotificationPreferences.isEnabled() {
                _ = await DailyVerseNotificationScheduler().requestAuthorizationIfNeeded()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appContainer, appContainer)
                .onOpenURL { url in
                    Task { await appContainer.oauth.handleIncomingCallback(url) }
                }
        }
    }
}
