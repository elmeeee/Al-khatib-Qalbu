//
//  HadithPresenter.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

struct HadithDisplayItem: Identifiable, Sendable, Equatable {
    let id: String
    let sourceName: String
    let referenceLabel: String?
    let chapterTitle: String?
    let body: String
    let gradeLines: [String]
}

@MainActor
@Observable
final class HadithPresenter {
    var isSheetPresented = false
    var isLoading = false
    var isLoadingMore = false
    var loadErrorDescription: String?
    var contentUnavailable = false
    var verseReference = ""
    var items: [HadithDisplayItem] = []
    var hasMore = false
    var selectedLanguage: AppLanguage = AppLanguageManager.shared.currentLanguage

    private var activeAyahKey: String?
    private var currentPage = 1
    private let pageLimit = 4
    private let content: QuranContentRepository

    init(content: QuranContentRepository) {
        self.content = content
    }

    func open(for verse: RandomAyahPayload) {
        guard let key = verse.verseKey, key.isEmpty == false else { return }
        activeAyahKey = key
        verseReference = ShareVerseCard.humanLabel(for: key)
        items = []
        loadErrorDescription = nil
        contentUnavailable = false
        hasMore = false
        currentPage = 1
        isLoading = true
        isSheetPresented = true
        Task { await reload() }
    }

    func prefetch(ayahKey: String) async {
        _ = try? await content.getHadithsByAyah(ayahKey: ayahKey, language: selectedLanguage.rawValue, page: 1, limit: 1)
    }

    func reload() async {
        guard let key = activeAyahKey else { return }
        currentPage = 1
        isLoading = true
        loadErrorDescription = nil
        contentUnavailable = false
        do {
            let response = try await content.getHadithsByAyah(
                ayahKey: key,
                language: selectedLanguage.rawValue,
                page: currentPage,
                limit: pageLimit
            )
            items = Self.mapItems(from: response)
            hasMore = response.hasMore == true
            contentUnavailable = items.isEmpty
        } catch {
            loadErrorDescription = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            items = []
            hasMore = false
            contentUnavailable = false
        }
        isLoading = false
    }

    func loadMore() async {
        guard let key = activeAyahKey, hasMore, isLoading == false, isLoadingMore == false else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1
        do {
            let response = try await content.getHadithsByAyah(
                ayahKey: key,
                language: selectedLanguage.rawValue,
                page: nextPage,
                limit: pageLimit
            )
            let newItems = Self.mapItems(from: response)
            items.append(contentsOf: newItems)
            currentPage = nextPage
            hasMore = response.hasMore == true
            contentUnavailable = items.isEmpty
        } catch {
            loadErrorDescription = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoadingMore = false
    }

    private static func mapItems(from response: HadithsByAyahResponse) -> [HadithDisplayItem] {
        (response.hadiths ?? []).compactMap { reference in
            guard let text = reference.hadith?.first,
                  let body = text.body?.trimmingCharacters(in: .whitespacesAndNewlines),
                  body.isEmpty == false else {
                return nil
            }

            let source = reference.name?.trimmingCharacters(in: .whitespacesAndNewlines)
            let sourceName = (source?.isEmpty == false) ? source! : (reference.collection ?? "Hadith")

            var referenceParts: [String] = []
            if let hadithNumber = reference.hadithNumber, hadithNumber.isEmpty == false {
                referenceParts.append("#\(hadithNumber)")
            }
            if let book = reference.bookNumber, book.isEmpty == false {
                referenceParts.append("Book \(book)")
            }

            let gradeLines = (text.grades ?? []).compactMap { grade -> String? in
                let by = grade.gradedBy?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let value = grade.grade?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if by.isEmpty && value.isEmpty { return nil }
                if by.isEmpty { return value }
                if value.isEmpty { return by }
                return "\(value) — \(by)"
            }

            let id = [
                reference.collection,
                reference.hadithNumber,
                String(reference.urn ?? 0),
                String(text.urn ?? 0)
            ]
            .compactMap { $0 }
            .joined(separator: "-")

            return HadithDisplayItem(
                id: id.isEmpty ? UUID().uuidString : id,
                sourceName: sourceName,
                referenceLabel: referenceParts.isEmpty ? nil : referenceParts.joined(separator: " · "),
                chapterTitle: text.chapterTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
                body: body,
                gradeLines: gradeLines
            )
        }
    }
}
