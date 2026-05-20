//
//  AppContainer.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import SwiftUI

private struct AppContainerKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue: AppContainer? = nil
}

extension EnvironmentValues {
    var appContainer: AppContainer? {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}

@MainActor
final class AppContainer {
    private var isClearingUserSession = false

    let environment: AppEnvironment
    let configuration: QFConfiguration
    let auth: QFAuthManager
    let userSession: QFUserSession
    let oauth: QFOAuthService
    let api: QFApiClient
    let content: QuranContentRepository
    let habits: UserHabitRepository
    let readingSessions: ReadingSessionRepository
    let reflect: ReflectRepository
    let reflectionStore: ReflectionStore

    init() {
        self.environment = .development
        self.configuration = environment.configuration.qfConfiguration
        self.auth = QFAuthManager(configuration: configuration, environment: environment)
        self.userSession = QFUserSession(environment: environment)
        self.oauth = QFOAuthService(configuration: configuration, userSession: userSession)
        self.api = QFApiClient(
            configuration: configuration,
            auth: auth,
            userSession: userSession
        )
        self.content = QuranContentRepository(client: api)
        self.habits = UserHabitRepository(client: api)
        self.readingSessions = ReadingSessionRepository(client: api)
        self.reflect = ReflectRepository(client: api, habits: habits)
        self.reflectionStore = ReflectionStore(appGroupIdentifier: configuration.appGroupIdentifier)
    }

    func makeSyncService() -> ReflectionSyncService {
        ReflectionSyncService(store: reflectionStore, reflect: reflect, habits: habits)
    }

    /// Logout or expired session — clears Keychain tokens, caches, and local Reflect data.
    func clearUserSession() async {
        if isClearingUserSession { return }
        isClearingUserSession = true
        defer { isClearingUserSession = false }
        await oauth.signOut()
        await APICache.clearAll()
        reflectionStore.removeAll()
    }

    /// Fire-and-forget sign-out after 401/403. Callers must not `await` this (e.g. Profile `.task`).
    func invalidateUserSession() {
        Task { @MainActor in
            await clearUserSession()
        }
    }

    func signOut() async {
        await clearUserSession()
    }

    func warmReflectDataIfSignedIn() {
        Task(priority: .utility) {
            guard await userSession.hasUserAccessToken() else { return }
            async let profile: Void = { _ = try? await habits.fetchMyProfile() }()
            async let feed: Void = { _ = try? await reflect.fetchFeed(page: 1, limit: 8) }()
            _ = await (profile, feed)
        }
    }

    func warmUserProfileIfSignedIn() {
        warmReflectDataIfSignedIn()
    }

    func warmChapterCatalog() {
        Task(priority: .utility) {
            _ = try? await content.getChapters()
        }
    }
}
