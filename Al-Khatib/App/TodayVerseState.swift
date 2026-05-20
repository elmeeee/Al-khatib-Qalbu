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

    /// Session notifications can fire while the OAuth sheet is still open; refresh after it closes.
    func handleOAuthFlowDidChange(container: AppContainer?) async {
        syncOAuthUIState(container: container)
        guard container?.oauth.isWebAuthInProgress != true else { return }
        guard let container, await container.userSession.hasUserAccessToken() else {
            applySignedOutProfile()
            hasResolvedSession = true
            return
        }
        await ensureProfileLoaded(container: container)
        container.warmReflectDataIfSignedIn()
    }

    func handleUserSessionDidChange(container: AppContainer?) async {
        guard container?.oauth.isWebAuthInProgress != true else { return }
        guard let container else { return }
        let hasToken = await container.userSession.hasUserAccessToken()
        if hasToken == false {
            await APICache.clearAll()
            applySignedOutProfile()
            hasResolvedSession = true
            return
        }
        await ensureProfileLoaded(container: container)
        container.warmReflectDataIfSignedIn()
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

    /// Fast session resolution for UI; profile network refresh continues in the background.
    func ensureProfileLoaded(container: AppContainer?) async {
        await applySessionSnapshot(container: container)
        enqueueProfileRefresh(container: container)
    }

    /// Blocks until profile network refresh finishes (sign-in, publish reflection).
    func ensureProfileLoadedAndAwait(container: AppContainer?) async {
        await applySessionSnapshot(container: container)
        if let profileRefreshTask {
            await profileRefreshTask.value
            return
        }
        await refreshProfile(container: container)
    }

    private func applySessionSnapshot(container: AppContainer?) async {
        guard let container else {
            hasResolvedSession = true
            return
        }
        if isLoggingIn || container.oauth.isWebAuthInProgress {
            return
        }

        let hasToken = await container.userSession.hasUserAccessToken()
        if hasToken {
            if let cached = await APICache.Profile.shared.cached() {
                userAvatarURL = cached.preferredAvatarURL
                userDisplayName = cached.displayTitle
                userId = cached.id
                isLoggedIn = true
            } else {
                isLoggedIn = false
            }
        } else {
            applySignedOutProfile()
        }
        hasResolvedSession = true
    }

    private func enqueueProfileRefresh(container: AppContainer?) {
        guard profileRefreshTask == nil else { return }
        profileRefreshTask = Task { @MainActor in
            await refreshProfile(container: container)
            profileRefreshTask = nil
        }
    }

    func refreshProfile(container: AppContainer?) async {
        guard let container else { return }
        if isLoggingIn || container.oauth.isWebAuthInProgress {
            return
        }
        isRefreshingProfile = true
        defer { isRefreshingProfile = false }

        let hasToken = await container.userSession.hasUserAccessToken()
        guard hasToken else {
            applySignedOutProfile()
            hasResolvedSession = true
            return
        }

        if let cached = await APICache.Profile.shared.cached() {
            userAvatarURL = cached.preferredAvatarURL
            userDisplayName = cached.displayTitle
            userId = cached.id
            isLoggedIn = true
        }

        do {
            let profile = try await container.habits.fetchMyProfile()
            userAvatarURL = profile.preferredAvatarURL
            userDisplayName = profile.displayTitle
            userId = profile.id
            isLoggedIn = true
        } catch {
            if Self.isAuthenticationFailure(error) {
                container.invalidateUserSession()
                applySignedOutProfile()
            } else if userId == nil {
                isLoggedIn = false
            } else {
                isLoggedIn = true
            }
        }
        hasResolvedSession = true
    }

    static func isAuthenticationFailure(_ error: Error) -> Bool {
        if case QFError.missingUserSession = error { return true }
        if case QFError.authExpired = error { return true }
        if case QFError.sessionForbidden = error { return true }
        if let qf = error as? QFError, case .parsingError(let detail) = qf {
            let lower = detail.lowercased()
            if lower.contains("http 401")
                || lower.contains("http 403")
                || lower.contains("invalid_grant")
                || lower.contains("invalid_token") {
                return true
            }
        }
        return false
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
        await ensureProfileLoadedAndAwait(container: container)
    }
}
