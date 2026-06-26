//
//  LocalHadithDataSource.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

internal final class LocalHadithDataSource: Sendable {
    private let cacheDir: URL

    internal init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cachePath = paths[0].appendingPathComponent("hadith_cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true, attributes: nil)
        self.cacheDir = cachePath
    }

    internal func getHadithsByAyah(
        ayahKey: String,
        page: Int = 1,
        limit: Int = 5,
        language: String = "en",
        fetcher: @escaping @Sendable () async throws -> HadithsByAyahResponse
    ) async throws -> HadithsByAyahResponse {
        if let cached = loadFromCache(ayahKey: ayahKey, page: page, language: language) {
            return cached
        }
        do {
            let response = try await fetcher()
            saveToCache(ayahKey: ayahKey, page: page, language: language, response: response)
            return response
        } catch {
            return HadithsByAyahResponse(hadiths: [], page: page, limit: limit, hasMore: false, language: nil, direction: nil)
        }
    }

    private func cacheFile(ayahKey: String, page: Int, language: String) -> URL {
        let safeKey = ayahKey.replacingOccurrences(of: ":", with: "_")
        return cacheDir.appendingPathComponent("\(safeKey)_\(language)_p\(page).json")
    }

    private func loadFromCache(ayahKey: String, page: Int, language: String) -> HadithsByAyahResponse? {
        let fileUrl = cacheFile(ayahKey: ayahKey, page: page, language: language)
        guard FileManager.default.fileExists(atPath: fileUrl.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileUrl)
            return try JSONDecoder().decode(HadithsByAyahResponse.self, from: data)
        } catch {
            return nil
        }
    }

    private func saveToCache(ayahKey: String, page: Int, language: String, response: HadithsByAyahResponse) {
        guard let hadiths = response.hadiths, !hadiths.isEmpty else { return }
        let fileUrl = cacheFile(ayahKey: ayahKey, page: page, language: language)
        do {
            let data = try JSONEncoder().encode(response)
            try data.write(to: fileUrl, options: .atomicWrite)
        } catch {
            print("Failed to save Hadith cache: \(error)")
        }
    }
}
