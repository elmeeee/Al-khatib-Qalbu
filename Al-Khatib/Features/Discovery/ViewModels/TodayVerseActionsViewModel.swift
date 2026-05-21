//
//  TodayVerseActionsViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class TodayVerseActionsViewModel {
    var isGeneratingShare = false
    let publishViewModel = TodayReflectionPublishViewModel()

    func presentShare(for verse: RandomAyahPayload, discovery: TodayDiscoveryViewModel) async {
        isGeneratingShare = true
        defer { isGeneratingShare = false }
        let text = await discovery.prepareShareText(for: verse)
        ShareVerseCard.presentPrepared(text: text)
    }

    func openTafsir(
        for verse: RandomAyahPayload,
        presenter: TafsirPresenter?,
        discovery: TodayDiscoveryViewModel
    ) {
        presenter?.open(for: verse)
        Task { await discovery.prefetchShareTextIfNeeded(for: verse) }
    }

    func publishReflection(
        for verse: RandomAyahPayload,
        discovery: TodayDiscoveryViewModel,
        verseState: TodayVerseState,
        container: AppContainer
    ) async {
        let outcome = await publishViewModel.publish(
            verse: verse,
            discovery: discovery,
            verseState: verseState,
            container: container
        )

        switch outcome {
        case .published:
            publishViewModel.presentStatus("Reflection published!", isError: false)
        case .needsSignIn:
            publishViewModel.presentStatus("Please sign in to publish a reflection.", isError: true)
        case .failed(let message):
            publishViewModel.presentStatus(message, isError: true)
        }

        await publishViewModel.hideStatusAfterDelay()
    }
}
