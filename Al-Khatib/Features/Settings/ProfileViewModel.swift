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

    func fetchProfile(force: Bool = false) async {
        guard await container.userSession.hasUserAccessToken() else {
            profile = nil
            isLoading = false
            return
        }
        if profile == nil {
            isLoading = true
        }
        errorMessage = nil
        do {
            profile = try await container.habits.fetchMyProfile(force: force)
        } catch {
            profile = nil
            if TodayVerseState.isAuthenticationFailure(error) {
                container.invalidateUserSession()
                errorMessage = nil
            } else {
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
