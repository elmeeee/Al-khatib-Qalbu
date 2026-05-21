//
//  TranslatorSelectionViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class TranslatorSelectionViewModel {
    var searchQuery = ""
    var translations: [QFTranslation] = []
    var isLoading = false
    var errorMessage: String?

    private let contentRepository: QuranContentRepository

    init(contentRepository: QuranContentRepository) {
        self.contentRepository = contentRepository
    }

    var filteredTranslations: [QFTranslation] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return translations }
        return translations.filter { trans in
            trans.authorName.localizedCaseInsensitiveContains(query)
                || trans.name.localizedCaseInsensitiveContains(query)
                || trans.languageName.localizedCaseInsensitiveContains(query)
        }
    }

    func loadTranslations() async {
        isLoading = true
        errorMessage = nil
        do {
            let res = try await contentRepository.getTranslations()
            translations = Self.sorted(res.translations)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func displayName(for translation: QFTranslation) -> String {
        translation.authorName.isEmpty ? translation.name : translation.authorName
    }

    func subtitle(for translation: QFTranslation) -> String {
        "\(translation.languageName.capitalized) · \(translation.name)"
    }

    private static func sorted(_ items: [QFTranslation]) -> [QFTranslation] {
        items.sorted { a, b in
            if a.languageName == "english" && b.languageName != "english" { return true }
            if b.languageName == "english" && a.languageName != "english" { return false }
            if a.languageName == b.languageName { return a.authorName < b.authorName }
            return a.languageName < b.languageName
        }
    }
}
