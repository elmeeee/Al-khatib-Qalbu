//
//  ProfileViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    var isLoading = true
    var errorMessage: String?
    var authBusy = false
    var profile: UserProfilePayload?

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    func hydrateFromCacheIfNeeded() async {
        guard profile == nil, let cached = await APICache.Profile.shared.cached() else { return }
        profile = cached
    }

    func fetchProfile(force: Bool = false) async {
        await hydrateFromCacheIfNeeded()

        let hasToken = await container.userSession.hasUserAccessToken()
        guard hasToken else {
            if profile == nil {
                isLoading = false
            }
            return
        }

        if profile == nil {
            isLoading = true
        }
        errorMessage = nil
        do {
            profile = try await container.habits.fetchMyProfile(force: force)
        } catch {
            if TodayVerseState.isAuthenticationFailure(error) {
                container.invalidateUserSession()
                profile = nil
                errorMessage = nil
            } else if profile == nil {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
        isLoading = false
    }

    func signIn() async {
        guard container.oauth.isWebAuthInProgress == false else { return }
        errorMessage = nil
        do {
            try await container.oauth.signIn()
            await fetchProfile(force: true)
        } catch {
            if error is CancellationError { return }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func signOut() async {
        authBusy = true
        errorMessage = nil
        defer { authBusy = false }
        await container.signOut()
        profile = nil
    }
}
