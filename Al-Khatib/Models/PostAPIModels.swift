//
//  PostAPIModels.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct PostCreateBody: Encodable, Sendable {
    var data: PostCreateData
}

struct PostCreateData: Encodable, Sendable {
    var body: String
    var draft: Bool
    var references: [QuranReference]
    var global: Bool
    var roomPostStatus: Int
}

struct QuranReference: Encodable, Sendable, Hashable {
    var id: String
    var from: Int
    var to: Int
    var chapterId: Int
}

struct PostCreateEnvelope: Decodable, Sendable {
    let data: UserPost
    let success: Bool
}

struct UserPost: Decodable, Sendable {
    let id: Int
    let body: String
}

struct StreaksPage: Decodable, Sendable {
    let data: [StreakRecord]?
    let pageInfo: PageInfo?
}

struct PageInfo: Decodable, Sendable {
    let hasNextPage: Bool?
    let endCursor: String?
}

struct StreakRecord: Decodable, Sendable, Identifiable {
    var id: String { String(rawId) }
    let rawId: String
    let startDate: String?
    let endDate: String?
    let days: Int?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case rawId = "id"
        case startDate, endDate, days, status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decode(String.self, forKey: .rawId) {
            rawId = s
        } else if let i = try? c.decode(Int.self, forKey: .rawId) {
            rawId = String(i)
        } else {
            rawId = "unknown"
        }
        startDate = try? c.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try? c.decodeIfPresent(String.self, forKey: .endDate)
        days = try? c.decodeIfPresent(Int.self, forKey: .days)
        status = try? c.decodeIfPresent(String.self, forKey: .status)
    }
}

struct ActivityDayInput: Encodable, Sendable {
    var type: String
    var day: String
    var timezone: String
    var versesRead: Int?
}

struct ActivityDayEnvelope: Decodable, Sendable {
    let success: Bool?
}
