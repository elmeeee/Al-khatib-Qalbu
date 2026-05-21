//
//  ContentView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isSplashActive = true
    @State private var verseState = TodayVerseState()

    var body: some View {
        Group {
            if isSplashActive {
                SplashScreenView()
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isSplashActive = false
                                }
                            }
                        }
                    }
            } else if hasCompletedOnboarding == false {
                OnboardingView()
            } else {
                RootTabView(verseState: verseState)
            }
        }
        .preferredColorScheme(.light)
        .tint(Color.Token.deepEmerald)
        .task(id: hasCompletedOnboarding) {
            guard hasCompletedOnboarding else { return }
            await verseState.ensureProfileLoaded(container: container)
            container?.warmChapterCatalog()
            container?.warmUserProfileIfSignedIn()
            _ = await DailyVerseNotificationCoordinator.refreshIfNeeded(container: container)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, hasCompletedOnboarding else { return }
            Task {
                _ = await DailyVerseNotificationCoordinator.refreshIfNeeded(container: container)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfOAuthWebAuthStateDidChange)) { _ in
            verseState.syncOAuthUIState(container: container)
            Task { @MainActor in
                await verseState.handleOAuthFlowDidChange(container: container)
                container?.warmReflectDataIfSignedIn()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                await verseState.handleUserSessionDidChange(container: container)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserProfileDidUpdate)) { _ in
            Task { @MainActor in
                await verseState.syncFromCachedProfile(container: container)
            }
        }
    }
}

struct SplashScreenView: View {
    @State private var scale = 0.8
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                Image("AlKhatibLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}
