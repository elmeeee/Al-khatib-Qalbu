//
//  DoaZikirViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class DoaZikirViewModel {
    var isLoading = false
    var catalog: [DoaCatalogEntry] = []
    var selectedSlug: String? = nil
    var selectedTitle: String? = nil
    var doaItems: [DoaItem] = []
    var dhikrBundles: [DhikrBundle] = []
    var errorMessage: String? = nil

    private let dataSource = LocalDoaDataSource()

    init() {}

    func loadCatalog() async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            catalog = try await dataSource.getCatalog()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectCategory(_ entry: DoaCatalogEntry) async {
        isLoading = true
        selectedSlug = entry.slug
        selectedTitle = entry.title
        doaItems = []
        dhikrBundles = []
        errorMessage = nil
        defer { isLoading = false }

        do {
            if entry.kind == .dhikr {
                dhikrBundles = try await dataSource.getDhikrBySlug(slug: entry.slug)
            } else {
                doaItems = try await dataSource.getDoasBySlug(slug: entry.slug)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearSelection() {
        selectedSlug = nil
        selectedTitle = nil
        doaItems = []
        dhikrBundles = []
    }
}
