//
//  ReflectionTabViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReflectionTabViewModel {
    enum Screen {
        case signIn
        case bootLoading
        case feed
        case sessionLoading
    }

    private(set) var hasAccessToken = false
    private(set) var feedViewModel: ReflectionViewModel?

    var screen: Screen {
        if shouldShowSignInPrompt { return .signIn }
        if canShowReflectFeed {
            return feedViewModel == nil ? .bootLoading : .feed
        }
        if hasResolvedSession == false || isRefreshingProfile { return .sessionLoading }
        if hasResolvedSession { return .signIn }
        return .sessionLoading
    }

    private var hasResolvedSession = false
    private var isRefreshingProfile = false
    private var isLoggedIn = false

    func sync(verseState: TodayVerseState) {
        hasResolvedSession = verseState.hasResolvedSession
        isRefreshingProfile = verseState.isRefreshingProfile
        isLoggedIn = verseState.isLoggedIn
    }

    var shouldShowSignInPrompt: Bool {
        hasResolvedSession && isLoggedIn == false && hasAccessToken == false
    }

    var canShowReflectFeed: Bool {
        hasAccessToken || isLoggedIn
    }

    func refreshAccessToken(using container: AppContainer?) async {
        guard let container else {
            hasAccessToken = false
            return
        }
        hasAccessToken = await container.userSession.hasUserAccessToken()
    }

    func openTab(container: AppContainer, verseState: TodayVerseState) async {
        sync(verseState: verseState)
        hasAccessToken = await container.userSession.hasUserAccessToken()
        guard hasAccessToken else {
            await verseState.ensureProfileLoaded(container: container)
            feedViewModel = nil
            return
        }

        ensureFeedViewModel(container: container)
        container.warmReflectDataIfSignedIn()
        feedViewModel?.scheduleLoad(refresh: true, force: false)

        hasAccessToken = await container.userSession.hasUserAccessToken()
        if hasAccessToken == false {
            feedViewModel = nil
        }
    }

    func bootstrapFeed(container: AppContainer, verseState: TodayVerseState, force: Bool) async {
        sync(verseState: verseState)
        ensureFeedViewModel(container: container)
        feedViewModel?.scheduleLoad(refresh: true, force: force)
        hasAccessToken = await container.userSession.hasUserAccessToken()
    }

    func handleSessionChange(
        container: AppContainer?,
        verseState: TodayVerseState,
        isTabSelected: Bool
    ) async {
        sync(verseState: verseState)
        guard let container else { return }
        hasAccessToken = await container.userSession.hasUserAccessToken()
        if hasAccessToken == false {
            feedViewModel = nil
            await verseState.ensureProfileLoaded(container: container)
        } else if isTabSelected {
            await bootstrapFeed(container: container, verseState: verseState, force: true)
        } else {
            container.warmReflectDataIfSignedIn()
        }
    }

    func handleLoggedInChange(
        container: AppContainer?,
        verseState: TodayVerseState,
        isTabSelected: Bool,
        loggedIn: Bool
    ) async {
        sync(verseState: verseState)
        if loggedIn {
            if isTabSelected, let container {
                await bootstrapFeed(container: container, verseState: verseState, force: true)
            }
        } else {
            feedViewModel = nil
            await refreshAccessToken(using: container)
        }
    }

    func clearFeed() {
        feedViewModel = nil
    }

    private func ensureFeedViewModel(container: AppContainer) {
        guard feedViewModel == nil else { return }
        let model = ReflectionViewModel(reflect: container.reflect)
        model.onSessionInvalidated = { @MainActor in
            container.invalidateUserSession()
        }
        feedViewModel = model
    }
}
