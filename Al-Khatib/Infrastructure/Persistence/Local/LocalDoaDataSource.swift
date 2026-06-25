//
//  LocalDoaDataSource.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

internal final class LocalDoaDataSource: Sendable {
    private let dhikrSlugs: Set<String> = [
        "morning-dhikir",
        "evening-dhikir",
        "dhikir-after-salah",
        "sleep-dhikir"
    ]

    internal init() {}

    internal func getCatalog() async throws -> [DoaCatalogEntry] {
        let categories = loadCategories().data ?? []
        return categories.compactMap { cat in
            guard let slug = cat.slug, !slug.isEmpty else { return nil }
            let title = (cat.name != nil && !cat.name!.isEmpty) ? cat.name! : slug
            let kind: DoaCatalogKind = dhikrSlugs.contains(slug) ? .dhikr : .doa
            return DoaCatalogEntry(slug: slug, title: title, kind: kind)
        }
    }

    internal func getDailyDoas() async throws -> [DoaItem] {
        return loadDoaResponse(fileName: "daily.json").data ?? []
    }

    internal func getDoasBySlug(slug: String) async throws -> [DoaItem] {
        let file = "duas_\(slug).json"
        if assetExists(path: "Resources/doa/\(file)") || assetExists(path: file) {
            return loadDoaResponse(fileName: file).data ?? []
        } else if slug == "daily" {
            return try await getDailyDoas()
        } else {
            return []
        }
    }

    internal func getDhikrBySlug(slug: String) async throws -> [DhikrBundle] {
        let file = "dhikir_\(slug).json"
        guard let data = readAsset(path: file) else { return [] }
        do {
            let response = try JSONDecoder().decode(DhikrListResponse.self, from: data)
            return response.data ?? []
        } catch {
            print("Failed to decode Dhikr response for \(slug): \(error)")
            return []
        }
    }

    private func loadCategories() -> DoaCategoriesResponse {
        guard let data = readAsset(path: "categories.json") else {
            return DoaCategoriesResponse(success: false, message: nil, data: [])
        }
        do {
            return try JSONDecoder().decode(DoaCategoriesResponse.self, from: data)
        } catch {
            print("Failed to decode categories.json: \(error)")
            return DoaCategoriesResponse(success: false, message: nil, data: [])
        }
    }

    private func loadDoaResponse(fileName: String) -> DoaListResponse {
        guard let data = readAsset(path: fileName) else {
            return DoaListResponse(success: false, message: nil, data: [])
        }
        do {
            return try JSONDecoder().decode(DoaListResponse.self, from: data)
        } catch {
            print("Failed to decode Doa file \(fileName): \(error)")
            return DoaListResponse(success: false, message: nil, data: [])
        }
    }

    private func assetExists(path: String) -> Bool {
        let filename = (path as NSString).lastPathComponent
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        return Bundle.main.url(forResource: name, withExtension: ext) != nil ||
            Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/doa") != nil
    }

    private func readAsset(path: String) -> Data? {
        let filename = (path as NSString).lastPathComponent
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension

        var url = Bundle.main.url(forResource: name, withExtension: ext)
        if url == nil {
            url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/doa")
        }
        guard let fileUrl = url else { return nil }
        return try? Data(contentsOf: fileUrl)
    }
}
