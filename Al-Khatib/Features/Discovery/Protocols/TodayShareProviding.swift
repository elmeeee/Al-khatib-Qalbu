//
//  TodayShareProviding.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

@MainActor
protocol TodayShareProviding: AnyObject {
    func prefetchShareTextIfNeeded(for verse: RandomAyahPayload) async
    func cachedShareText(for verse: RandomAyahPayload) -> String?
    func quickReflectionText(for verse: RandomAyahPayload) -> String
    func prepareShareText(for verse: RandomAyahPayload) async -> String
}

extension TodayShareTextComposer: TodayShareProviding {}

extension TodayDiscoveryViewModel: TodayShareProviding {}
