//
//  PostAPIModels.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct PostCreateRequest: Encodable, Sendable {
    var post: PostCreatePayload
}

struct PostCreatePayload: Encodable, Sendable {
    var body: String
    var draft: Bool
    var references: [PostCreateReference]
    var mentions: [PostCreateMention]
    var roomPostStatus: Int
    var roomId: Int
    var postAsAuthorId: String
    var publishedAt: String
}

struct PostCreateMention: Encodable, Sendable { }

struct PostCreateReference: Encodable, Sendable, Hashable {
    var chapterId: Int
    var from: Int
    var to: Int
    var id: String

    init(chapterId: Int, from: Int, to: Int) {
        self.chapterId = chapterId
        self.from = from
        self.to = to
        self.id = "surah-\(chapterId)-\(from):\(to)"
    }
}

struct PostCreateEnvelope: Decodable, Sendable {
    let success: Bool?
    let data: UserPost?
    let post: UserPost?

    var createdPost: UserPost? {
        data ?? post
    }
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
            rawId = ""
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

struct ReflectFeedEnvelope: Decodable, Sendable {
    let total: Int?
    let currentPage: Int?
    let limit: Int?
    let pages: Int?
    let data: [ReflectFeedPost]?

    enum CodingKeys: String, CodingKey {
        case total, currentPage, limit, pages, data, posts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        total = try c.decodeIfPresent(Int.self, forKey: .total)
        currentPage = try c.decodeIfPresent(Int.self, forKey: .currentPage)
        limit = try c.decodeIfPresent(Int.self, forKey: .limit)
        pages = try c.decodeIfPresent(Int.self, forKey: .pages)
        if let rows = try? c.decode([ReflectFeedPost].self, forKey: .data) {
            data = rows
        } else if let rows = try? c.decode([ReflectFeedPost].self, forKey: .posts) {
            data = rows
        } else {
            data = []
        }
    }
}

struct ReflectFeedPost: Decodable, Sendable, Identifiable {
    let id: String
    let body: String?
    let author: ReflectFeedAuthor?
    let references: [ReflectFeedReference]?
    let tags: [ReflectFeedTag]?
    let recentComment: ReflectFeedComment?
    let isLiked: Bool?
    let createdAt: String?
    let draft: Bool?
    let likesCount: Int?
    let commentsCount: Int?
    let postTypeName: String?

    enum CodingKeys: String, CodingKey {
        case id, body, author, references, tags, recentComment
        case isLiked, createdAt, draft, likesCount, commentsCount, postTypeName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try Self.decodeFeedID(from: c)
        body = try c.decodeIfPresent(String.self, forKey: .body)
        author = try? c.decode(ReflectFeedAuthor.self, forKey: .author)
        references = try? c.decode([ReflectFeedReference].self, forKey: .references)
        tags = try? c.decode([ReflectFeedTag].self, forKey: .tags)
        recentComment = try? c.decode(ReflectFeedComment.self, forKey: .recentComment)
        isLiked = try c.decodeIfPresent(Bool.self, forKey: .isLiked)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        draft = try c.decodeIfPresent(Bool.self, forKey: .draft)
        likesCount = try c.decodeIfPresent(Int.self, forKey: .likesCount)
        commentsCount = try c.decodeIfPresent(Int.self, forKey: .commentsCount)
        postTypeName = try c.decodeIfPresent(String.self, forKey: .postTypeName)
    }

    private static func decodeFeedID(from c: KeyedDecodingContainer<CodingKeys>) throws -> String {
        if let intID = try? c.decode(Int.self, forKey: .id) {
            return String(intID)
        }
        if let stringID = try? c.decode(String.self, forKey: .id) {
            return stringID
        }
        if let doubleID = try? c.decode(Double.self, forKey: .id) {
            return String(Int64(doubleID))
        }
        throw DecodingError.dataCorruptedError(
            forKey: .id,
            in: c,
            debugDescription: "post id missing or invalid"
        )
    }
}

struct ReflectFeedTag: Decodable, Sendable {
    let language: String?
    let id: Int?
    let name: String?
}

struct ReflectFeedRoom: Decodable, Sendable {
    let id: Int?
    let subdomain: String?
    let roomType: String?
    let name: String?
}

struct ReflectFeedMention: Decodable, Sendable {
    let id: String?
    let username: String?
    let firstName: String?
    let lastName: String?
    let displayName: String?
    let verified: Bool?
}

struct ReflectFeedComment: Decodable, Sendable {
    let id: String?
    let body: String?
    let createdAt: String?
    let author: ReflectFeedAuthor?

    enum CodingKeys: String, CodingKey {
        case id, body, createdAt, author
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let intID = try? c.decode(Int.self, forKey: .id) {
            id = String(intID)
        } else {
            id = try c.decodeIfPresent(String.self, forKey: .id)
        }
        body = try c.decodeIfPresent(String.self, forKey: .body)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        author = try? c.decode(ReflectFeedAuthor.self, forKey: .author)
    }
}

struct ReflectFeedAuthor: Decodable, Sendable {
    let id: String?
    let username: String?
    let firstName: String?
    let lastName: String?
    let verified: Bool?
    let avatarUrls: UserProfileAvatarUrls?

    enum CodingKeys: String, CodingKey {
        case id, username, firstName, lastName, verified, avatarUrls
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let stringID = try? c.decode(String.self, forKey: .id) {
            id = stringID
        } else if let intID = try? c.decode(Int.self, forKey: .id) {
            id = String(intID)
        } else {
            id = nil
        }
        username = try c.decodeIfPresent(String.self, forKey: .username)
        firstName = try c.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try c.decodeIfPresent(String.self, forKey: .lastName)
        verified = try c.decodeIfPresent(Bool.self, forKey: .verified)
        avatarUrls = try? c.decode(UserProfileAvatarUrls.self, forKey: .avatarUrls)
    }

    var displayName: String {
        let parts = [firstName, lastName].compactMap { $0 }.filter { $0.isEmpty == false }
        if parts.isEmpty == false { return parts.joined(separator: " ") }
        if let username, username.isEmpty == false { return username }
        return id ?? "Contributor"
    }

    var avatarURL: URL? {
        let s = avatarUrls?.medium ?? avatarUrls?.large ?? avatarUrls?.small
        guard let s, let url = URL(string: s) else { return nil }
        return url
    }
}

struct ReflectFeedReference: Decodable, Sendable {
    let id: String?
    let from: Int?
    let to: Int?
    let chapterId: Int?

    var verseKey: String? {
        if let chapterId, let from {
            return "\(chapterId):\(from)"
        }
        if let id, id.isEmpty == false {
            return VerseKeyFormat.canonical(from: id)
        }
        return nil
    }
}

enum VerseKeyFormat {
    static func canonical(from raw: String) -> String {
        if raw.hasPrefix("surah-") {
            let rest = String(raw.dropFirst("surah-".count))
            guard let colon = rest.firstIndex(of: ":") else { return raw }
            let chapterAyah = rest[..<colon]
            let segments = chapterAyah.split(separator: "-")
            if segments.count >= 2,
               let chapter = Int(segments[0]),
               let ayah = Int(segments[segments.count - 1]) {
                return "\(chapter):\(ayah)"
            }
        }
        return raw
    }

    static func humanLabel(for verseKey: String) -> String {
        let key = canonical(from: verseKey)
        let parts = key.split(separator: ":")
        guard parts.count == 2,
              let chapter = Int(parts[0]),
              let ayah = Int(parts[1]) else {
            return verseKey
        }
        let index = chapter - 1
        let surahName = surahNames.indices.contains(index) ? surahNames[index] : "Surah \(chapter)"
        return "\(surahName) - Ayah \(ayah)"
    }
    
    // All 114 surah names (transliterated, standard Quran ordering)
    private static let surahNames: [String] = [
        "Al-Fatihah", "Al-Baqarah", "Ali 'Imran", "An-Nisa", "Al-Ma'idah",
        "Al-An'am", "Al-A'raf", "Al-Anfal", "At-Tawbah", "Yunus",
        "Hud", "Yusuf", "Ar-Ra'd", "Ibrahim", "Al-Hijr",
        "An-Nahl", "Al-Isra", "Al-Kahf", "Maryam", "Taha",
        "Al-Anbya", "Al-Hajj", "Al-Mu'minun", "An-Nur", "Al-Furqan",
        "Ash-Shu'ara", "An-Naml", "Al-Qasas", "Al-'Ankabut", "Ar-Rum",
        "Luqman", "As-Sajdah", "Al-Ahzab", "Saba", "Fatir",
        "Ya-Sin", "As-Saffat", "Sad", "Az-Zumar", "Ghafir",
        "Fussilat", "Ash-Shura", "Az-Zukhruf", "Ad-Dukhan", "Al-Jathiyah",
        "Al-Ahqaf", "Muhammad", "Al-Fath", "Al-Hujurat", "Qaf",
        "Adh-Dhariyat", "At-Tur", "An-Najm", "Al-Qamar", "Ar-Rahman",
        "Al-Waqi'ah", "Al-Hadid", "Al-Mujadila", "Al-Hashr", "Al-Mumtahanah",
        "As-Saf", "Al-Jumu'ah", "Al-Munafiqun", "At-Taghabun", "At-Talaq",
        "At-Tahrim", "Al-Mulk", "Al-Qalam", "Al-Haqqah", "Al-Ma'arij",
        "Nuh", "Al-Jinn", "Al-Muzzammil", "Al-Muddaththir", "Al-Qiyamah",
        "Al-Insan", "Al-Mursalat", "An-Naba", "An-Nazi'at", "'Abasa",
        "At-Takwir", "Al-Infitar", "Al-Mutaffifin", "Al-Inshiqaq", "Al-Buruj",
        "At-Tariq", "Al-A'la", "Al-Ghashiyah", "Al-Fajr", "Al-Balad",
        "Ash-Shams", "Al-Layl", "Ad-Duhaa", "Ash-Sharh", "At-Tin",
        "Al-'Alaq", "Al-Qadr", "Al-Bayyinah", "Az-Zalzalah", "Al-'Adiyat",
        "Al-Qari'ah", "At-Takathur", "Al-'Asr", "Al-Humazah", "Al-Fil",
        "Quraysh", "Al-Ma'un", "Al-Kawthar", "Al-Kafirun", "An-Nasr",
        "Al-Masad", "Al-Ikhlas", "Al-Falaq", "An-Nas"
    ]
}
