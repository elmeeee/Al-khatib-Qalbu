//
//  TafsirPresenter.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

struct CachedTafsir: Sendable {
    let html: String
    let plainText: String?
    let sourceName: String
}

@MainActor
@Observable
final class TafsirPresenter {
    var isSheetPresented = false
    var isLoading = false
    var htmlFragment = ""
    var loadErrorDescription: String?
    var commentaryUnavailable = false
    var verseReference = ""
    var commentarySource: String?

    private var activeAyahKey: String?
    private var cache: [String: CachedTafsir] = [:]
    private var cacheAccessOrder: [String] = []
    private let maxCachedAyahs = 12
    private let content: QuranContentRepository
    private let resourceId: String

    init(content: QuranContentRepository, resourceId: String = "169") {
        self.content = content
        self.resourceId = resourceId
    }

    func open(for verse: RandomAyahPayload) {
        guard let key = verse.verseKey, key.isEmpty == false else { return }
        activeAyahKey = key
        verseReference = ShareVerseCard.humanLabel(for: key)
        commentarySource = nil
        htmlFragment = ""
        loadErrorDescription = nil
        commentaryUnavailable = false
        isLoading = true
        isSheetPresented = true
        Task { await reload() }
    }

    func prefetch(ayahKey: String) async {
        guard cache[ayahKey] == nil else { return }
        _ = try? await loadCached(ayahKey: ayahKey)
    }

    func reload() async {
        guard let key = activeAyahKey else { return }
        isLoading = true
        loadErrorDescription = nil
        commentaryUnavailable = false
        do {
            let cached = try await loadCached(ayahKey: key)
            commentarySource = cached.sourceName
            htmlFragment = cached.html
            commentaryUnavailable = cached.html.isEmpty
        } catch {
            loadErrorDescription = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            htmlFragment = ""
            commentaryUnavailable = false
            commentarySource = nil
        }
        isLoading = false
    }

    private func loadCached(ayahKey: String) async throws -> CachedTafsir {
        if let cached = cache[ayahKey] {
            cacheAccessOrder.removeAll { $0 == ayahKey }
            cacheAccessOrder.append(ayahKey)
            return cached
        }
        let response = try await content.getTafsirByAyah(resourceId: resourceId, ayahKey: ayahKey)
        let html = response.tafsir?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let plainText = response.tafsir?.textStrippingHTML?.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceName = response.tafsir?.resourceName ?? "Tafsir Ibn Kathir (English)"
        let result = CachedTafsir(html: html, plainText: plainText, sourceName: sourceName)
        rememberCache(ayahKey: ayahKey, result: result)
        return result
    }

    private func rememberCache(ayahKey: String, result: CachedTafsir) {
        cache[ayahKey] = result
        cacheAccessOrder.removeAll { $0 == ayahKey }
        cacheAccessOrder.append(ayahKey)
        while cacheAccessOrder.count > maxCachedAyahs {
            guard let victim = cacheAccessOrder.first(where: { $0 != activeAyahKey }) else { break }
            cacheAccessOrder.removeAll { $0 == victim }
            cache.removeValue(forKey: victim)
        }
    }
}
