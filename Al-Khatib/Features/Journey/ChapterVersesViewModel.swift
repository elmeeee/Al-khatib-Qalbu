//
//  ChapterVersesViewModel.swift
//  Al-Khatib
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
    var errorMessage: String?

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
