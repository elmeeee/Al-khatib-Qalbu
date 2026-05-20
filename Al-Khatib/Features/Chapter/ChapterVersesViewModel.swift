//
//  ChapterVersesViewModel.swift
//  Al-Khatib
//

import Foundation
import Observation

@MainActor
@Observable
final class ChapterVersesViewModel {
    static let defaultRecitationId = 6
    private static let recitationStorageKey = "chapterReaderRecitationId"

    let chapter: QuranChapter

    var verses: [RandomAyahPayload] = []
    var isLoading = false
    var isLoadingMore = false
    var isPreparingPlayAll = false
    var isReloadingRecitation = false
    var errorMessage: String?
    var recitations: [RecitationPayload] = []
    var selectedRecitationId: Int
    var selectedArabicTextStyle: QuranArabicTextStyle

    var surahDisplayTitle: String { chapter.displayComplexName }
    var reciterDisplayName: String {
        recitations.first(where: { $0.identifiableId == selectedRecitationId })?.displayName ?? ""
    }

    private let content: QuranContentRepository
    private var nextPage = 1
    private var hasMorePages = true

    init(chapter: QuranChapter, content: QuranContentRepository) {
        self.chapter = chapter
        self.content = content
        let saved = UserDefaults.standard.integer(forKey: Self.recitationStorageKey)
        selectedRecitationId = saved > 0 ? saved : Self.defaultRecitationId
        selectedArabicTextStyle = QuranArabicTextStyle.savedOrDefault()
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
            if recitations.contains(where: { $0.identifiableId == selectedRecitationId }) == false,
               let first = recitations.first?.identifiableId {
                selectedRecitationId = first
            }
        }
    }

    func applyContentPreferencesChange() async {
        guard isReloadingRecitation == false else { return }
        UserDefaults.standard.set(selectedRecitationId, forKey: Self.recitationStorageKey)
        selectedArabicTextStyle.persist()
        isReloadingRecitation = true
        defer { isReloadingRecitation = false }

        let targetCount = max(verses.count, 1)
        var accumulated: [RandomAyahPayload] = []
        var page = 1
        var stillHasMore = true

        repeat {
            do {
                let response = try await content.getVersesByChapter(
                    chapterNumber: chapter.id,
                    recitationId: selectedRecitationId,
                    arabicTextStyle: selectedArabicTextStyle,
                    page: page,
                    perPage: 50
                )
                accumulated.append(contentsOf: response.verses)
                if response.pagination?.hasNextPage == true,
                   let next = response.pagination?.nextPage {
                    page = next
                    stillHasMore = true
                } else {
                    stillHasMore = false
                }
            } catch {
                if accumulated.isEmpty {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
                return
            }
        } while stillHasMore && accumulated.count < targetCount

        verses = accumulated
        nextPage = page
        hasMorePages = stillHasMore
    }

    func ensureAllVersesLoaded() async {
        while hasMorePages {
            await fetchPage(nextPage, append: true)
        }
    }

    func audioQueueItems() -> [AudioQueueItem] {
        return verses.compactMap { verse in
            guard let url = verse.audio?.url, url.isEmpty == false else { return nil }
            return AudioQueueItem(url: url, subtitle: ayahSubtitle(for: verse))
        }
    }

    func ayahSubtitle(for verse: RandomAyahPayload) -> String {
        if let number = verse.verseNumber {
            return "\(number)"
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
                recitationId: selectedRecitationId,
                arabicTextStyle: selectedArabicTextStyle,
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
