//
//  QuranChaptersViewModel.swift
//  Al-Khatib
//

import Foundation
import Observation

@MainActor
@Observable
final class QuranChaptersViewModel {
    var chapters: [QuranChapter] = []
    var isLoading = false
    var errorMessage: String?

    private let content: QuranContentRepository
    private let language: String

    init(content: QuranContentRepository, language: String = "en") {
        self.content = content
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
}
