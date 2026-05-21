//
//  VerseDetailViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class VerseDetailViewModel {
    var isLoading = false
    var verseSheetData: SingleVerseResponse?
    var selectedVerseKey: String?

    func open(verseKey: String, content: QuranContentRepository?) async {
        isLoading = true
        verseSheetData = nil
        selectedVerseKey = verseKey

        defer { isLoading = false }

        guard let content else { return }
        do {
            verseSheetData = try await content.getVerseByKey(verseKey: verseKey)
        } catch {
            verseSheetData = nil
        }
    }

    func reset() {
        isLoading = false
        verseSheetData = nil
        selectedVerseKey = nil
    }
}
