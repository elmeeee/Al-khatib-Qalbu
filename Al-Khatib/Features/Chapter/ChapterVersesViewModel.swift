//
//  ChapterVersesViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class ChapterVersesViewModel {
    let chapter: QuranChapter

    var verses: [RandomAyahPayload] = []
    var isLoading = false
    var isLoadingMore = false
    var isPreparingPlayAll = false
    var errorMessage: String?
    var recitations: [RecitationPayload] = []
    var selectedRecitationId: Int = 6

    var surahDisplayTitle: String { chapter.displayComplexName }
    var reciterDisplayName: String {
        recitations.first(where: { $0.id == selectedRecitationId })?.displayName ?? ""
    }

    private let content: QuranContentRepository
    private var nextPage = 1
    private var hasMorePages = true

    init(chapter: QuranChapter, content: QuranContentRepository) {
        self.chapter = chapter
        self.content = content
    }

    func loadInitial() async {
        guard isLoading == false else { return }
        isLoading = true
        errorMessage = nil
        verses = []
        nextPage = 1
        hasMorePages = true
        defer { isLoading = false }

        await fetchPage(1, append: false)
        await loadRecitationsIfNeeded()
    }

    func loadRecitationsIfNeeded() async {
        guard recitations.isEmpty else { return }
        if let fetched = try? await content.getRecitations().recitations {
            recitations = fetched
        }
    }

    func ensureAllVersesLoaded() async {
        while hasMorePages {
            await fetchPage(nextPage, append: true)
        }
    }

    func audioQueueItems() -> [AudioQueueItem] {
        let reciter = reciterDisplayName
        return verses.compactMap { verse in
            guard let url = verse.audio?.url, url.isEmpty == false else { return nil }
            let label = ayahSubtitle(for: verse)
            let subtitle = reciter.isEmpty ? label : "\(label) — \(reciter)"
            return AudioQueueItem(url: url, subtitle: subtitle)
        }
    }

    func ayahSubtitle(for verse: RandomAyahPayload) -> String {
        if let number = verse.verseNumber {
            return "Ayah \(number)"
        }
        if let key = verse.verseKey {
            return ShareVerseCard.humanLabel(for: key)
        }
        return "Ayah"
    }

    func loadMoreIfNeeded(currentVerse: RandomAyahPayload?) async {
        guard hasMorePages, isLoadingMore == false, isLoading == false else { return }
        guard let currentVerse else { return }
        guard let last = verses.last, last.listIdentity == currentVerse.listIdentity else {
            return
        }
        isLoadingMore = true
        defer { isLoadingMore = false }
        await fetchPage(nextPage, append: true)
    }

    private func fetchPage(_ page: Int, append: Bool) async {
        do {
            let response = try await content.getVersesByChapter(
                chapterNumber: chapter.id,
                page: page,
                perPage: 50
            )
            if append {
                verses.append(contentsOf: response.verses)
            } else {
                verses = response.verses
            }
            if response.pagination?.hasNextPage == true,
               let next = response.pagination?.nextPage {
                nextPage = next
                hasMorePages = true
            } else {
                hasMorePages = false
            }
        } catch {
            if append == false {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}
