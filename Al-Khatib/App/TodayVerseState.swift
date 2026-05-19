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
    /// True while the first (or in-flight) profile request is running.
    var isRefreshingProfile = false
    /// False until at least one profile refresh attempt has finished.
    var hasResolvedSession = false

    private var profileRefreshTask: Task<Void, Never>?

    // Today's Reflect button — holds the AI-enhanced reflection text
    // so it can be passed through to ShareReflectionSheet.
    var preparedShareText: String?

    func setVerse(key: String?, label: String?, arabic: String?) {
        activeVerseKey = key
        activeVerseLabel = label
        activeArabicSnippet = arabic
    }

    /// Triggers navigation to Reflect tab.
    /// `shareText` is the AI-enhanced reflection body from TodayDiscoveryViewModel.
    /// If nil, the user will type manually.
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

    private func applySignedOutProfile() {
        isLoggedIn = false
        userAvatarURL = nil
        userDisplayName = nil
        userId = nil
    }

    /// Loads profile once; concurrent callers await the same in-flight request.
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
            // Keep the session on transient failures so we do not prompt sign-in incorrectly.
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

    /// Triggers OAuth sign-in flow and refreshes profile on success.
    func signIn(container: AppContainer?) async {
        guard let container else { return }
        isLoggingIn = true
        defer { isLoggingIn = false }
        do {
            try await container.oauth.signIn()
            await ensureProfileLoaded(container: container)
        } catch {
            // Sign-in cancelled or failed — stay on current state
        }
    }
}
