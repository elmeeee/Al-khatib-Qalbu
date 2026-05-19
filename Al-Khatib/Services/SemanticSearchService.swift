//
//  SemanticSearchService.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct SemanticSearchService: Sendable {
    private let client: QFApiClient
    private let configuration: QFConfiguration

    init(client: QFApiClient, configuration: QFConfiguration) {
        self.client = client
        self.configuration = configuration
    }

}
