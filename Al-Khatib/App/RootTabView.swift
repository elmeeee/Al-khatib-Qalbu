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
        case today, journey, tools, reflect, account
    }

    enum TodayNavigation: Hashable {
        case account
    }

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appContainer) private var container
    @State private var selectedTab: Tab = .today
    @State private var todayNavigationPath: [TodayNavigation] = []
    @State private var vm = RootTabViewModel()
    let verseState: TodayVerseState

    init(verseState: TodayVerseState) {
        self.verseState = verseState
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.Token.pureWhite)
        appearance.shadowColor = UIColor(Color.Token.softGrey)

        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.Token.deepEmerald)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.Token.deepEmerald)]

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
            }
            .tag(Tab.today)
            .tabItem { Label("Today", systemImage: "sun.max.fill") }
            .alKhatibAccessibility(label: AlKhatibAccessibility.Tab.today, hint: AlKhatibAccessibility.Tab.todayHint)

            ChaptersView()
                .tag(Tab.journey)
                .tabItem { Label("Quran", systemImage: "book.fill") }
                .alKhatibAccessibility(label: AlKhatibAccessibility.Tab.quran, hint: AlKhatibAccessibility.Tab.quranHint)

            NavigationStack {
                SpiritualToolsView()
            }
            .tag(Tab.tools)
            .tabItem { Label("Tools", systemImage: "grid") }

            ReflectionView(
                verseState: verseState,
                isTabSelected: selectedTab == .reflect
            )
            .tag(Tab.reflect)
            .tabItem { Label("Reflect", systemImage: "square.and.pencil") }
            .alKhatibAccessibility(label: AlKhatibAccessibility.Tab.reflect, hint: AlKhatibAccessibility.Tab.reflectHint)

            NavigationStack {
                ProfileView(preferSystemNavigationTitle: true, verseState: verseState)
                    .environment(\.appContainer, container)
            }
            .tag(Tab.account)
            .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
        .onChangeWithFallback(of: verseState.shouldNavigateToReflect) { shouldNavigate in
            if shouldNavigate {
                if selectedTab != .reflect {
                    withAnimation { selectedTab = .reflect }
                }
            }
        }
        .onChangeWithFallback(of: verseState.shouldNavigateToAccount) { shouldNavigate in
            if shouldNavigate {
                selectedTab = .account
                verseState.didNavigateToAccount()
            }
        }
        .onChangeWithFallback(of: verseState.shouldSelectTodayTab) { shouldSelect in
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
        .onChangeWithFallback(of: scenePhase) { p in
            if p == .active {
                Task {
                    guard container?.oauth.isWebAuthInProgress == false else { return }
                    await verseState.ensureProfileLoaded(container: container)
                    await vm.runSync(container: container)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: DailyVerseNotificationPreferences.openTodayTabNotification)) { _ in
            verseState.selectTodayTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                guard container?.oauth.isWebAuthInProgress == false else { return }
                guard await vm.shouldResetToDiscover(container: container) else { return }
                if selectedTab != .today {
                    selectedTab = .today
                }
                if todayNavigationPath.isEmpty == false {
                    await Task.yield()
                    todayNavigationPath = []
                }
            }
        }
    }
}
