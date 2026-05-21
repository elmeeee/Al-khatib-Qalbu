//
//  ReadingSessionTracker.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

@MainActor
final class ReadingSessionTracker {
    private let repository: ReadingSessionRepository
    private let userSession: QFUserSession
    private let debounceNanoseconds: UInt64

    private var debounceTask: Task<Void, Never>?
    private var pendingChapter: Int?
    private var pendingVerse: Int?
    private var lastSentChapter: Int?
    private var lastSentVerse: Int?

    init(
        repository: ReadingSessionRepository,
        userSession: QFUserSession,
        debounceSeconds: TimeInterval = 1.5
    ) {
        self.repository = repository
        self.userSession = userSession
        self.debounceNanoseconds = UInt64(debounceSeconds * 1_000_000_000)
    }

    func updateVisibleAyah(chapterNumber: Int, verseNumber: Int) {
        guard chapterNumber >= 1, verseNumber >= 1 else { return }
        if lastSentChapter == chapterNumber, lastSentVerse == verseNumber { return }

        pendingChapter = chapterNumber
        pendingVerse = verseNumber
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: self?.debounceNanoseconds ?? 1_500_000_000)
            guard Task.isCancelled == false else { return }
            await self?.flushPending()
        }
    }

    func flush() async {
        debounceTask?.cancel()
        debounceTask = nil
        await flushPending()
    }

    private func flushPending() async {
        guard let chapter = pendingChapter, let verse = pendingVerse else { return }
        pendingChapter = nil
        pendingVerse = nil

        guard await userSession.hasUserAccessToken() else { return }
        if lastSentChapter == chapter, lastSentVerse == verse { return }

        do {
            try await repository.upsertReadingSession(chapterNumber: chapter, verseNumber: verse)
            lastSentChapter = chapter
            lastSentVerse = verse
        } catch QFError.missingUserSession {
            return
        } catch {
            return
        }
    }
}
