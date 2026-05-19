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
    var shouldNavigateToAccount = false
    var shouldSelectTodayTab = false
    var isLoggedIn = false
    var userAvatarURL: URL?
    var userDisplayName: String?
    var isLoggingIn = false

    func setVerse(key: String?, label: String?, arabic: String?) {
        activeVerseKey = key
        activeVerseLabel = label
        activeArabicSnippet = arabic
    }

    func requestReflect() {
        shouldNavigateToReflect = true
    }

    func didNavigateToReflect() {
        shouldNavigateToReflect = false
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
    }

    func refreshProfile(container: AppContainer?) async {
        guard let container else { return }
        let hasToken = await container.userSession.hasUserAccessToken()
        guard hasToken else {
            applySignedOutProfile()
            return
        }
        do {
            let profile = try await container.habits.fetchMyProfile()
            userAvatarURL = profile.preferredAvatarURL
            userDisplayName = profile.displayTitle
            isLoggedIn = true
        } catch QFError.networkError {
            applySignedOutProfile()
        } catch {
            await container.userSession.clear()
            await MainActor.run {
                applySignedOutProfile()
            }
        }
    }

    /// Triggers OAuth sign-in flow and refreshes profile on success.
    func signIn(container: AppContainer?) async {
        guard let container else { return }
        isLoggingIn = true
        defer { isLoggingIn = false }
        do {
            try await container.oauth.signIn()
            await refreshProfile(container: container)
        } catch {
            // Sign-in cancelled or failed — stay on current state
        }
    }
}
