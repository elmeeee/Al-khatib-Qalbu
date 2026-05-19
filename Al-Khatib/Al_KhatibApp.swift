//
//  Al_KhatibApp.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI
import Prowl

@main
struct Al_KhatibApp: App {
    private let appContainer: AppContainer

    init() {
        Prowl.start()
        self.appContainer = AppContainer()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appContainer, appContainer)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    Task { await appContainer.oauth.handleIncomingCallback(url) }
                }
        }
    }
}
