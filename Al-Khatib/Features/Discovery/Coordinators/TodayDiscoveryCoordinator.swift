//
//  TodayDiscoveryCoordinator.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class TodayDiscoveryCoordinator {
    var discoveryViewModel: TodayDiscoveryViewModel?
    var dashboardViewModel: PrayerDashboardViewModel?
    var tafsirPresenter: TafsirPresenter?

    let prayer: PrayerTimesController
    let audio: AudioPlayerController

    init(prayer: PrayerTimesController, audio: AudioPlayerController) {
        self.prayer = prayer
        self.audio = audio
    }

    func bootstrap(container: AppContainer, verseState: TodayVerseState) async {
        if dashboardViewModel == nil {
            dashboardViewModel = PrayerDashboardViewModel(controller: prayer)
        }
        await verseState.syncFromCachedProfile(container: container)

        guard discoveryViewModel == nil else {
            discoveryViewModel?.autoRefreshDailyAyahIfNeeded(forceIfNoData: true)
            prayer.refreshIfNeeded()
            return
        }

        let vm = TodayDiscoveryViewModel(content: container.content)
        discoveryViewModel = vm
        if tafsirPresenter == nil {
            tafsirPresenter = TafsirPresenter(content: container.content)
        }
        vm.autoRefreshDailyAyahIfNeeded(forceIfNoData: true)
        prayer.refreshIfNeeded()
    }

    func onVerseKeyChanged(
        _ newKey: String?,
        verseState: TodayVerseState,
        discovery: TodayDiscoveryViewModel
    ) {
        let arabic = discovery.detail?.displayText ?? ""
        let label = newKey.flatMap { ShareVerseCard.humanLabel(for: $0) }
        verseState.setVerse(key: newKey, label: label, arabic: arabic)

        guard let newKey else { return }
        Task {
            await tafsirPresenter?.prefetch(ayahKey: newKey)
            if let verse = discovery.detail {
                await discovery.prefetchShareTextIfNeeded(for: verse)
            }
        }
    }

    func refreshToday(discovery: TodayDiscoveryViewModel?) async {
        async let prayerRefresh: Void = prayer.forceRefresh()
        if let discovery {
            await discovery.refreshDailyAyah()
        }
        await prayerRefresh
    }

    func stopAudio() {
        audio.stop()
    }
}
