//
//  RootTabViewModel.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class RootTabViewModel {
    func runSync(container: AppContainer?) async {
        guard let container else { return }
        await container.makeSyncService().syncPending()
    }

    func shouldResetToDiscover(container: AppContainer?) async -> Bool {
        guard let container else { return false }
        return await container.userSession.hasUserAccessToken() == false
    }
}
