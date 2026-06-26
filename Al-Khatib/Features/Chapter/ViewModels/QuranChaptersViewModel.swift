//
//  QuranChaptersViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class QuranChaptersViewModel {
    var chapters: [QuranChapter] = []
    var juzs: [QuranJuz] = []
    var continueReading: ReadingSession?
    var isLoading = false
    var isLoadingJuzs = false
    var isLoadingContinueReading = false
    var errorMessage: String?
    var errorMessageJuzs: String?

    // ── Search ──────────────────────────────────────────────────────────
    var searchText: String = ""
    var isSearchActive: Bool = false

    var filteredChapters: [QuranChapter] {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard q.isEmpty == false else { return chapters }
        return chapters.searchChapters(query: q)
    }

    private let content: QuranContentRepository
    private let readingSessions: ReadingSessionRepository
    private let language: String

    init(
        content: QuranContentRepository,
        readingSessions: ReadingSessionRepository,
        language: String = AppLanguageManager.shared.currentLanguage.rawValue
    ) {
        self.content = content
        self.readingSessions = readingSessions
        self.language = language
    }

    func loadChapters(force: Bool = false) async {
        if isLoading { return }
        if chapters.isEmpty == false, force == false { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            chapters = try await content.getChapters(language: language)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func loadJuzs(force: Bool = false) async {
        if isLoadingJuzs { return }
        if juzs.isEmpty == false, force == false { return }

        isLoadingJuzs = true
        errorMessageJuzs = nil
        defer { isLoadingJuzs = false }

        do {
            juzs = try await content.getJuzs()
        } catch {
            errorMessageJuzs = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func loadContinueReading() async {
        isLoadingContinueReading = true
        defer { isLoadingContinueReading = false }

        do {
            continueReading = try await readingSessions.fetchMostRecent()
        } catch QFError.missingUserSession {
            continueReading = nil
        } catch {
            continueReading = nil
        }
    }

    func chapter(for session: ReadingSession) -> QuranChapter? {
        chapters.first { $0.id == session.chapterNumber }
    }

    func continueReadingRoute() -> ChapterReaderRoute? {
        guard let session = continueReading,
              let chapter = chapter(for: session) else {
            return nil
        }
        return ChapterReaderRoute(
            chapter: chapter,
            juzNumber: nil,
            initialVerseNumber: session.verseNumber
        )
    }

    func refreshAll(force: Bool = false) async {
        async let chaptersTask: Void = loadChapters(force: force)
        async let juzsTask: Void = loadJuzs(force: force)
        async let continueTask: Void = loadContinueReading()
        _ = await (chaptersTask, juzsTask, continueTask)
    }
    func setSearch(_ text: String) {
        searchText = text
    }

    func clearSearch() {
        searchText = ""
        isSearchActive = false
    }
}
