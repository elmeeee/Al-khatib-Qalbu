//
//  RootTabView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct RootTabView: View {
    enum Tab: Hashable {
        case today, reflect, journey
    }

    private enum TodayNavigation: Hashable {
        case account
    }

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appContainer) private var container
    @State private var selectedTab: Tab = .today
    @State private var todayNavigationPath = NavigationPath()
    @State private var vm = RootTabViewModel()
    @State private var verseState = TodayVerseState()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.Theme.pureWhite)
        appearance.shadowColor = UIColor(Color.Theme.softGrey)

        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.Theme.deepEmerald)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.Theme.deepEmerald)]

        appearance.stackedLayoutAppearance.normal.iconColor = .lightGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $todayNavigationPath) {
                TodayDiscoveryView(verseState: verseState)
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: TodayNavigation.self) { destination in
                        switch destination {
                        case .account:
                            ProfileView(preferSystemNavigationTitle: true)
                                .navigationTitle("Account")
                                .navigationBarTitleDisplayMode(.large)
                                .toolbar(.visible, for: .navigationBar)
                        }
                    }
            }
            .tag(Tab.today)
            .tabItem { Label("Today", systemImage: "sun.max.fill") }
            ReflectionView(verseState: verseState)
                .tag(Tab.reflect)
                .tabItem { Label("Reflect", systemImage: "square.and.pencil") }
            JourneyView(verseState: verseState)
                .tag(Tab.journey)
                .tabItem { Label("Journey", systemImage: "flame.fill") }
        }
        .onChange(of: selectedTab) { _, newTab in
            guard newTab == .journey else { return }
            Task { @MainActor in
                await verseState.refreshProfile(container: container)
                guard verseState.isLoggedIn == false else { return }
                guard verseState.isLoggingIn == false else { return }
                await verseState.signIn(container: container)
                if verseState.isLoggedIn == false {
                    verseState.selectTodayTab()
                }
            }
        }
        .onChange(of: verseState.shouldNavigateToReflect) { _, shouldNavigate in
            if shouldNavigate {
                if selectedTab != .reflect {
                    withAnimation { selectedTab = .reflect }
                }
                verseState.didNavigateToReflect()
            }
        }
        .onChange(of: verseState.shouldNavigateToAccount) { _, shouldNavigate in
            if shouldNavigate {
                if todayNavigationPath.isEmpty {
                    todayNavigationPath.append(TodayNavigation.account)
                }
                verseState.didNavigateToAccount()
            }
        }
        .onChange(of: verseState.shouldSelectTodayTab) { _, shouldSelect in
            if shouldSelect {
                if selectedTab != .today {
                    withAnimation { selectedTab = .today }
                }
                verseState.didSelectTodayTab()
            }
        }
        .onChange(of: scenePhase) { _, p in
            if p == .active {
                Task { await vm.runSync(container: container) }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                guard await vm.shouldResetToDiscover(container: container) else { return }
                if selectedTab != .today {
                    selectedTab = .today
                }
                if todayNavigationPath.isEmpty == false {
                    todayNavigationPath = NavigationPath()
                }
            }
        }
    }
}
