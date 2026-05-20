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

    func signOut() async {
        await oauth.signOut()
        await APICache.clearAll()
        reflectionStore.removeAll()
    }
}
