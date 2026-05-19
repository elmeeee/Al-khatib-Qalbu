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

    func fetchProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            profile = try await container.habits.fetchMyProfile()
        } catch QFError.missingUserSession {
            profile = nil
            errorMessage = "missing_user_session"
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            profile = nil
        }
        isLoading = false
    }

    func signIn() async {
        authBusy = true
        errorMessage = nil
        defer { authBusy = false }
        do {
            try await container.oauth.signIn()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func signOut() async {
        authBusy = true
        errorMessage = nil
        defer { authBusy = false }
        await container.oauth.signOut()
        profile = nil
    }
}
