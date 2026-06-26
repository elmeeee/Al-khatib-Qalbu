//
//  ChapterReaderCoordinator.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ChapterReaderCoordinator {
    enum ScrollID {
        static let intro = "chapter-intro"
    }

    var tafsirPresenter: TafsirPresenter?
    var hadithPresenter: HadithPresenter?
    var readingTracker: ReadingSessionTracker?
    var scrollPosition: String? = ScrollID.intro
    var lastAppliedTranslationId = ChapterReaderPreferences.defaultTranslationId
    var reservesReaderChromeForAudio = false

    let chapter: QuranChapter?
    let juzNumber: Int?
    let audio: AudioPlayerController

    init(chapter: QuranChapter?, juzNumber: Int?, audio: AudioPlayerController) {
        self.chapter = chapter
        self.juzNumber = juzNumber
        self.audio = audio
    }

    var isOnIntroPage: Bool {
        scrollPosition == ScrollID.intro || scrollPosition == nil
    }

    func bootstrap(container: AppContainer) -> ChapterVersesViewModel {
        let model = ChapterVersesViewModel(chapter: chapter, juzNumber: juzNumber, content: container.content)
        if chapter == nil {
            scrollPosition = nil
        }
        if tafsirPresenter == nil {
            tafsirPresenter = TafsirPresenter(content: container.content)
        }
        if hadithPresenter == nil {
            hadithPresenter = HadithPresenter(content: container.content)
        }
        if readingTracker == nil {
            readingTracker = ReadingSessionTracker(
                repository: container.readingSessions,
                userSession: container.userSession
            )
        }
        return model
    }

    func applyInitialScrollIfNeeded(vm: ChapterVersesViewModel, initialVerseNumber: Int?) {
        if let target = initialVerseNumber, target >= 1 {
            if let verse = vm.verses.first(where: { $0.resolvedVerseNumber == target }) {
                scrollToVerse(identity: verse.listIdentity)
                return
            }
        }
        if chapter == nil, let first = vm.verses.first {
            scrollToVerse(identity: first.listIdentity)
        }
    }

    func onScrollPositionChanged(_ newID: String?, vm: ChapterVersesViewModel) {
        guard let newID, newID != ScrollID.intro else { return }
        guard let verse = vm.verses.first(where: { $0.listIdentity == newID }) else { return }
        trackReadingSession(for: verse)
        Task {
            if let key = verse.verseKey {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await self.tafsirPresenter?.prefetch(ayahKey: key) }
                    group.addTask { await self.hadithPresenter?.prefetch(ayahKey: key) }
                }
            }
            await vm.loadMoreIfNeeded(currentVerse: verse)
        }
    }

    func onAudioURLChanged(_ url: String?, vm: ChapterVersesViewModel) {
        if url == nil {
            reservesReaderChromeForAudio = false
            return
        }
        guard audio.isPlayingSequence == false else { return }
        Task { @MainActor in
            await Task.yield()
            syncScrollToPlayingVerse(vm: vm)
        }
    }

    func onActiveSequenceIndexChanged(vm: ChapterVersesViewModel) {
        guard audio.isPlayingSequence else { return }
        Task { @MainActor in
            await Task.yield()
            syncScrollToPlayingVerse(vm: vm)
        }
    }

    func onDisappear() {
        reservesReaderChromeForAudio = false
        Task { await readingTracker?.flush() }
        audio.stop()
    }

    func currentVerse(in vm: ChapterVersesViewModel) -> RandomAyahPayload? {
        guard let scrollPosition, scrollPosition != ScrollID.intro else { return nil }
        return vm.verses.first(where: { $0.listIdentity == scrollPosition })
    }

    func openTafsirForCurrentAyah(in vm: ChapterVersesViewModel) {
        guard let verse = currentVerse(in: vm) else { return }
        tafsirPresenter?.open(for: verse)
    }

    func openHadithForCurrentAyah(in vm: ChapterVersesViewModel) {
        guard let verse = currentVerse(in: vm) else { return }
        hadithPresenter?.open(for: verse)
    }

    func positionLabel(in vm: ChapterVersesViewModel?) -> String {
        guard let vm, let scrollPosition, scrollPosition != ScrollID.intro else {
            return ""
        }
        if let index = vm.verses.firstIndex(where: { $0.listIdentity == scrollPosition }) {
            let verse = vm.verses[index]
            let verseNumber = verse.resolvedVerseNumber ?? (index + 1)
            let label = AppLanguageManager.shared.currentLanguage == .english ? "Verse" : "Ayah"
            if let juz = verse.juzNumber {
                return "\(label) (\(verseNumber)) • \(AppLanguageManager.shared.localize("juz")) \(juz)"
            }
            return "\(label) \(verseNumber)"
        }
        return ""
    }

    @MainActor
    func handleTap(for verse: RandomAyahPayload, vm: ChapterVersesViewModel) {
        guard let url = verse.audio?.url else { return }
        let reciter = vm.reciterDisplayName
        let ayah = vm.ayahSubtitle(for: verse)

        if audio.isPlayingURL(url) {
            audio.toggle()
            return
        }

        scrollToVerse(identity: verse.listIdentity)
        audio.playVerse(
            url: url,
            surahTitle: vm.surahDisplayTitle,
            ayahLabel: ayah,
            reciterName: reciter
        )
    }

    @MainActor
    func playEntireSurah(vm: ChapterVersesViewModel) async {
        vm.isPreparingPlayAll = true
        defer { vm.isPreparingPlayAll = false }

        await vm.ensureAllVersesLoaded()
        let items = vm.audioQueueItems()
        guard items.isEmpty == false else { return }

        reservesReaderChromeForAudio = true

        if let firstItem = items.first {
            let targetURL = AppEndpoints.URLBuilder.absoluteVerseMediaURLString(from: firstItem.url)
            if let first = vm.verses.first(where: { verse in
                guard let url = verse.audio?.url else { return false }
                return AppEndpoints.URLBuilder.absoluteVerseMediaURLString(from: url) == targetURL
            }) {
                scrollToVerse(identity: first.listIdentity)
                await Task.yield()
                try? await Task.sleep(nanoseconds: 80_000_000)
            }
        }

        audio.playSequence(
            items: items,
            surahTitle: vm.surahDisplayTitle,
            reciterName: vm.reciterDisplayName,
            startIndex: 0
        )
    }

    private func trackReadingSession(for verse: RandomAyahPayload) {
        guard let verseNumber = verse.resolvedVerseNumber else { return }
        guard let chapterNumber = chapter?.id else { return }
        readingTracker?.updateVisibleAyah(chapterNumber: chapterNumber, verseNumber: verseNumber)
    }

    @MainActor
    private func syncScrollToPlayingVerse(vm: ChapterVersesViewModel) {
        guard let verse = verseMatchingPlayback(in: vm) else { return }
        scrollToVerse(identity: verse.listIdentity)
    }

    private func verseMatchingPlayback(in vm: ChapterVersesViewModel) -> RandomAyahPayload? {
        if let index = audio.activeSequenceIndex,
           let item = audio.queueItem(at: index) {
            let target = AppEndpoints.URLBuilder.absoluteVerseMediaURLString(from: item.url)
            return vm.verses.first { verse in
                guard let url = verse.audio?.url else { return false }
                return AppEndpoints.URLBuilder.absoluteVerseMediaURLString(from: url) == target
            }
        }
        return vm.verses.first { audio.isPlayingURL($0.audio?.url) }
    }

    private func scrollToVerse(identity: String) {
        guard scrollPosition != identity else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            scrollPosition = identity
        }
        Task { @MainActor in
            await Task.yield()
            guard scrollPosition != identity else { return }
            var retry = Transaction()
            retry.disablesAnimations = true
            withTransaction(retry) {
                scrollPosition = identity
            }
        }
    }
}
