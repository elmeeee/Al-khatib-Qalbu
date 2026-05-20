//
//  ReadingSessionModels.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct ReadingSession: Decodable, Sendable, Identifiable, Hashable {
    let id: String
    let updatedAt: String?
    let chapterNumber: Int
    let verseNumber: Int
}

struct ReadingSessionsPage: Decodable, Sendable {
    let success: Bool?
    let data: [ReadingSession]?
    let pagination: CursorPagination?
}

struct CursorPagination: Decodable, Sendable {
    let startCursor: String?
    let endCursor: String?
    let hasNextPage: Bool?
    let hasPreviousPage: Bool?
}
