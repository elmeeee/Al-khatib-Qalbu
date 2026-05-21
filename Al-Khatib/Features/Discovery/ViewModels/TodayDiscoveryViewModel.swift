//
//  TodayDiscoveryViewModel.swift
//  Al-Khatib
//

import Foundation
import Observation

@MainActor
@Observable
final class TodayDiscoveryViewModel {
    var errorMessage: String?
    var detail: RandomAyahPayload?
    var isDetailLoading = false
    var recitations: [RecitationPayload] = []
    var selectedRecitationId: Int = 6

    private let content: QuranContentRepository
    private let shareComposer: TodayShareTextComposer
    private let defaults = UserDefaults.standard
    private var loadedTranslationId: Int?
    private var dailyAyahFetchGeneration = 0

    init(content: QuranContentRepository, shareComposer: TodayShareTextComposer? = nil) {
        self.content = content
        self.shareComposer = shareComposer ?? TodayShareTextComposer(content: content)
    }

    // MARK: - Daily ayah

    func loadDailyAyahWithHadith() {
        detail = nil
        errorMessage = nil
        isDetailLoading = true
        Task { await performDailyAyahFetch(clearDetailOnStart: true) }
    }

    func autoRefreshDailyAyahIfNeeded(forceIfNoData: Bool = true) {
        guard isDetailLoading == false else { return }
        let selected = ChapterReaderPreferences.selectedTranslationId(defaults: defaults)
        if let loaded = loadedTranslationId, loaded != selected {
            reloadForTranslationChange()
            return
        }
        if shouldRefreshRandomAyah(forceIfNoData: forceIfNoData) {
            loadDailyAyahWithHadith()
        }
    }

    func reloadForTranslationChange() {
        guard isDetailLoading == false else { return }
        loadedTranslationId = nil
        DailyAyahRefreshPolicy.clearLastFetch(defaults: defaults)
        shareComposer.clearCaches()
        loadDailyAyahWithHadith()
    }

    func refreshDailyAyah() async {
        errorMessage = nil
        isDetailLoading = true
        await performDailyAyahFetch(clearDetailOnStart: false)
    }

    // MARK: - Share (delegates to composer)

    func prefetchShareTextIfNeeded(for verse: RandomAyahPayload) async {
        await shareComposer.prefetchShareTextIfNeeded(for: verse)
    }

    func cachedShareText(for verse: RandomAyahPayload) -> String? {
        shareComposer.cachedShareText(for: verse)
    }

    func quickReflectionText(for verse: RandomAyahPayload) -> String {
        shareComposer.quickReflectionText(for: verse)
    }

    func prepareShareText(for verse: RandomAyahPayload) async -> String {
        await shareComposer.prepareShareText(for: verse)
    }

    // MARK: - Fetch

    private func performDailyAyahFetch(clearDetailOnStart: Bool) async {
        dailyAyahFetchGeneration += 1
        let generation = dailyAyahFetchGeneration

        if clearDetailOnStart {
            detail = nil
        }
        isDetailLoading = true
        errorMessage = nil
        defer {
            if generation == dailyAyahFetchGeneration {
                isDetailLoading = false
            }
        }

        do {
            async let ayahTask = content.getRandomAyah()
            async let recitationsTask: [RecitationPayload]? = recitations.isEmpty
                ? (try? content.getRecitations().recitations)
                : nil

            let response = try await ayahTask
            guard generation == dailyAyahFetchGeneration else { return }
            guard let verse = response.verse else {
                throw QFError.parsingError("daily verse payload")
            }

            detail = .init(verse)
            loadedTranslationId = ChapterReaderPreferences.selectedTranslationId(defaults: defaults)
            DailyAyahRefreshPolicy.markFetched(defaults: defaults)

            if let fetched = await recitationsTask, fetched.isEmpty == false {
                recitations = fetched
            }
        } catch {
            guard generation == dailyAyahFetchGeneration else { return }
            guard NetworkLoadErrorPolicy.shouldSurface(error) else { return }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func shouldRefreshRandomAyah(forceIfNoData: Bool) -> Bool {
        DailyAyahRefreshPolicy.shouldRefresh(
            lastFetchTimestamp: DailyAyahRefreshPolicy.lastFetchTimestamp(defaults: defaults),
            forceIfNoData: forceIfNoData,
            hasDetail: detail != nil
        )
    }
}
