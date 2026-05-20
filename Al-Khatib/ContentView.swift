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
        .tint(Color.Theme.deepEmerald)
        .task(id: hasCompletedOnboarding) {
            guard hasCompletedOnboarding else { return }
            await verseState.ensureProfileLoaded(container: container)
            container?.warmUserProfileIfSignedIn()
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
