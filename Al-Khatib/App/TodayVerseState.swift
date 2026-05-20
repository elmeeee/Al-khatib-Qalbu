//
//  TodayVerseState.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class TodayVerseState {
    var activeVerseKey: String?
    var activeVerseLabel: String?
    var activeArabicSnippet: String?
    var shouldNavigateToReflect = false
    var feedNeedsRefresh = false
    var shouldNavigateToAccount = false
    var shouldSelectTodayTab = false
    var isLoggedIn = false
    var userAvatarURL: URL?
    var userDisplayName: String?
    var userId: String?
    var isLoggingIn = false
    var isRefreshingProfile = false
    var hasResolvedSession = false

    private var profileRefreshTask: Task<Void, Never>?
    var preparedShareText: String?

    func setVerse(key: String?, label: String?, arabic: String?) {
        activeVerseKey = key
        activeVerseLabel = label
        activeArabicSnippet = arabic
    }

    func requestReflect(shareText: String? = nil) {
        preparedShareText = shareText
        shouldNavigateToReflect = true
    }

    func didNavigateToReflect() {
        shouldNavigateToReflect = false
    }

    func notifyFeedDidUpdate() {
        feedNeedsRefresh = true
    }

    func didRefreshFeed() {
        feedNeedsRefresh = false
    }

    func requestAccount() {
        shouldNavigateToAccount = true
    }

    func didNavigateToAccount() {
        shouldNavigateToAccount = false
    }

    func selectTodayTab() {
        shouldSelectTodayTab = true
    }

    func didSelectTodayTab() {
        shouldSelectTodayTab = false
    }

    func syncOAuthUIState(container: AppContainer?) {
        isLoggingIn = container?.oauth.isWebAuthInProgress ?? false
    }

    private func applySignedOutProfile() {
        guard isLoggingIn == false else { return }
        profileRefreshTask?.cancel()
        profileRefreshTask = nil
        isLoggingIn = false
        isRefreshingProfile = false
        isLoggedIn = false
        userAvatarURL = nil
        userDisplayName = nil
        userId = nil
        preparedShareText = nil
        shouldNavigateToReflect = false
        shouldNavigateToAccount = false
        feedNeedsRefresh = false
    }

    func ensureProfileLoaded(container: AppContainer?) async {
        if let profileRefreshTask {
            await profileRefreshTask.value
            return
        }
        let task = Task { @MainActor in
            await refreshProfile(container: container)
        }
        profileRefreshTask = task
        await task.value
        profileRefreshTask = nil
    }

    func refreshProfile(container: AppContainer?) async {
        guard let container else { return }
        if isLoggingIn || container.oauth.isWebAuthInProgress {
            return
        }
        isRefreshingProfile = true
        defer {
            isRefreshingProfile = false
            hasResolvedSession = true
        }

        let hasToken = await container.userSession.hasUserAccessToken()
        guard hasToken else {
            applySignedOutProfile()
            return
        }
        do {
            let profile = try await container.habits.fetchMyProfile()
            userAvatarURL = profile.preferredAvatarURL
            userDisplayName = profile.displayTitle
            userId = profile.id
            isLoggedIn = true
        } catch QFError.networkError {
            if await container.userSession.hasUserAccessToken() {
                isLoggedIn = true
            } else {
                applySignedOutProfile()
            }
        } catch {
            await container.userSession.clear()
            applySignedOutProfile()
        }
    }

    func signIn(container: AppContainer?) async {
        guard let container else { return }
        if container.oauth.isWebAuthInProgress {
            return
        }
        do {
            try await container.oauth.signIn()
        } catch {
            return
        }
        await ensureProfileLoaded(container: container)
    }
}
