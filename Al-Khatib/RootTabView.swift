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
    let verseState: TodayVerseState

    init(verseState: TodayVerseState) {
        self.verseState = verseState
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
            ReflectionView(
                verseState: verseState,
                isTabSelected: selectedTab == .reflect
            )
            .tag(Tab.reflect)
            .tabItem { Label("Reflect", systemImage: "square.and.pencil") }
            ChaptersView()
                .tag(Tab.journey)
                .tabItem { Label("Quran", systemImage: "book.fill") }
        }
        .onChange(of: verseState.shouldNavigateToReflect) { _, shouldNavigate in
            if shouldNavigate {
                if selectedTab != .reflect {
                    withAnimation { selectedTab = .reflect }
                }
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
        .onReceive(NotificationCenter.default.publisher(for: .qfOAuthWebAuthStateDidChange)) { _ in
            verseState.syncOAuthUIState(container: container)
        }
        .onChange(of: scenePhase) { _, p in
            if p == .active {
                Task {
                    guard container?.oauth.isWebAuthInProgress == false else { return }
                    await verseState.ensureProfileLoaded(container: container)
                    await vm.runSync(container: container)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                guard container?.oauth.isWebAuthInProgress == false else { return }
                await verseState.ensureProfileLoaded(container: container)
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
