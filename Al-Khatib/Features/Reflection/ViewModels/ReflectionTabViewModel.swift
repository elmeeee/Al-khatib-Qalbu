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
    private(set) var hasAccessToken = false
    private(set) var feedViewModel: ReflectionViewModel?

    var screen: ReflectTabScreen {
        guard hasResolvedSession else { return .sessionLoading }

        if isLoggedIn {
            return .feed
        }

        if hasAccessToken {
            return feedViewModel == nil ? .bootLoading : .feed
        }

        return .signIn
    }

    private var hasResolvedSession = false
    private var isRefreshingProfile = false
    private var isLoggedIn = false

    func sync(verseState: TodayVerseState) {
        hasResolvedSession = verseState.hasResolvedSession
        isRefreshingProfile = verseState.isRefreshingProfile
        isLoggedIn = verseState.isLoggedIn
    }

    var canShowReflectFeed: Bool {
        isLoggedIn
    }

    func refreshAccessToken(using container: AppContainer?) async {
        guard let container else {
            hasAccessToken = false
            return
        }
        hasAccessToken = await container.userSession.hasUserAccessToken()
    }

    func prepareFeedIfNeeded(container: AppContainer) {
        ensureFeedViewModel(container: container)
    }

    func openTab(container: AppContainer, verseState: TodayVerseState) async {
        sync(verseState: verseState)
        await refreshAccessToken(using: container)

        if isLoggedIn {
            ensureFeedViewModel(container: container)
            container.warmReflectDataIfSignedIn()
            feedViewModel?.scheduleLoad(refresh: true, force: false)
            return
        }

        if hasAccessToken {
            await verseState.ensureProfileLoadedAndAwait(container: container)
            sync(verseState: verseState)
            await refreshAccessToken(using: container)
            guard isLoggedIn else {
                feedViewModel = nil
                return
            }
            ensureFeedViewModel(container: container)
            container.warmReflectDataIfSignedIn()
            feedViewModel?.scheduleLoad(refresh: true, force: false)
            return
        }

        await verseState.ensureProfileLoaded(container: container)
        sync(verseState: verseState)
        feedViewModel = nil
    }

    func bootstrapFeed(container: AppContainer, verseState: TodayVerseState, force: Bool) async {
        sync(verseState: verseState)
        await refreshAccessToken(using: container)
        guard isLoggedIn else {
            feedViewModel = nil
            return
        }
        ensureFeedViewModel(container: container)
        feedViewModel?.scheduleLoad(refresh: true, force: force)
    }

    func handleSessionChange(
        container: AppContainer?,
        verseState: TodayVerseState,
        isTabSelected: Bool
    ) async {
        sync(verseState: verseState)
        guard let container else { return }
        await refreshAccessToken(using: container)
        if hasAccessToken == false {
            feedViewModel = nil
            await verseState.ensureProfileLoaded(container: container)
            sync(verseState: verseState)
        } else if isTabSelected {
            if isLoggedIn == false {
                await verseState.ensureProfileLoadedAndAwait(container: container)
                sync(verseState: verseState)
                await refreshAccessToken(using: container)
            }
            if isLoggedIn {
                await bootstrapFeed(container: container, verseState: verseState, force: true)
            } else {
                feedViewModel = nil
            }
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
