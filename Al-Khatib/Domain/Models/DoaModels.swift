//
//  DoaModels.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

internal struct DoaCategory: Codable, Hashable, Sendable {
    internal let id: String?
    internal let name: String?
    internal let slug: String?
    internal let photo: String?
}

internal struct DoaItem: Codable, Hashable, Sendable, Identifiable {
    internal var id: String {
        return _id ?? UUID().uuidString
    }
    private let _id: String?
    internal let title: String?
    internal let arabic: String?
    internal let latin: String?
    internal let translation: String?
    internal let notes: String?
    internal let fawaid: String?
    internal let source: String?
    internal let category: String?
    internal let categories: DoaCategory?

    private enum CodingKeys: String, CodingKey {
        case _id = "id"
        case title, arabic, latin, translation, notes, fawaid, source, category, categories
    }
}

internal struct DoaListResponse: Codable, Sendable {
    internal let success: Bool?
    internal let message: String?
    internal let data: [DoaItem]?
}

internal struct DhikrContentItem: Codable, Hashable, Sendable {
    internal let arabic: String?
    internal let latin: String?
    internal let translation: String?
    internal let fawaid: String?
    internal let notes: String?
    internal let source: String?
    internal let repeatCount: Int?

    private enum CodingKeys: String, CodingKey {
        case repeatCount = "repeat_count"
        case arabic, latin, translation, fawaid, notes, source
    }
}

internal struct DhikrBundle: Codable, Hashable, Sendable, Identifiable {
    internal var id: String {
        return title ?? UUID().uuidString
    }
    internal let title: String?
    internal let category: String?
    internal let compiledBy: String?
    internal let content: [DhikrContentItem]?

    private enum CodingKeys: String, CodingKey {
        case compiledBy = "compiled_by"
        case title, category, content
    }
}

internal struct DhikrListResponse: Codable, Sendable {
    internal let success: Bool?
    internal let message: String?
    internal let data: [DhikrBundle]?
}

internal struct DoaCategoriesResponse: Codable, Sendable {
    internal let success: Bool?
    internal let message: String?
    internal let data: [DoaCategory]?
}

internal enum DoaCatalogKind: String, Codable, Sendable {
    case doa = "DOA"
    case dhikr = "DHIKR"
}

internal struct DoaCatalogEntry: Codable, Hashable, Sendable, Identifiable {
    internal var id: String { slug }
    internal let slug: String
    internal let title: String
    internal let kind: DoaCatalogKind
}
