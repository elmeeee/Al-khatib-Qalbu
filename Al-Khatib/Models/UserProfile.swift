//
//  UserProfile.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct UserProfileAvatarUrls: Decodable, Sendable {
    let small: String?
    let medium: String?
    let large: String?
}

struct UserProfileSettings: Decodable, Sendable {
    let ayahLanguages: [Int]?
    let reflectionLanguages: [Int]?
}

struct UserProfilePayload: Decodable, Sendable {
    let avatarUrls: UserProfileAvatarUrls?
    let createdAt: String?
    let joiningYear: Int?
    let isPasswordSet: Bool?
    let settings: UserProfileSettings?
    let username: String?
    let id: String
    let verified: Bool?
    let postAs: Bool?
    let firstName: String?
    let lastName: String?
    let postsCount: Int?
    let averageToxicity: Double?
    let languageId: Int?
    let banned: Bool?
    let memberType: Int?
    let followersCount: Int?
    let likesCount: Int?
    let isAdmin: Bool?
    let languageIsoCode: String?
    let bio: String?
    let country: String?
    let followed: Bool?

    enum CodingKeys: String, CodingKey {
        case avatarUrls, createdAt, joiningYear, isPasswordSet, settings
        case username, id, verified, postAs, firstName, lastName
        case postsCount, averageToxicity, languageId, banned, memberType
        case followersCount, likesCount, isAdmin, languageIsoCode, bio, country, followed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        avatarUrls = try c.decodeIfPresent(UserProfileAvatarUrls.self, forKey: .avatarUrls)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        joiningYear = try c.decodeIfPresent(Int.self, forKey: .joiningYear)
        isPasswordSet = try c.decodeIfPresent(Bool.self, forKey: .isPasswordSet)
        settings = try c.decodeIfPresent(UserProfileSettings.self, forKey: .settings)
        username = try c.decodeIfPresent(String.self, forKey: .username)

        if let s = try? c.decode(String.self, forKey: .id) {
            id = s
        } else if let i = try? c.decode(Int.self, forKey: .id) {
            id = String(i)
        } else {
            id = ""
        }

        verified = try c.decodeIfPresent(Bool.self, forKey: .verified)
        postAs = try c.decodeIfPresent(Bool.self, forKey: .postAs)
        firstName = try c.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try c.decodeIfPresent(String.self, forKey: .lastName)
        postsCount = try c.decodeIfPresent(Int.self, forKey: .postsCount)

        if let d = try? c.decode(Double.self, forKey: .averageToxicity) {
            averageToxicity = d
        } else if let i = try? c.decode(Int.self, forKey: .averageToxicity) {
            averageToxicity = Double(i)
        } else {
            averageToxicity = nil
        }

        languageId = try c.decodeIfPresent(Int.self, forKey: .languageId)
        banned = try c.decodeIfPresent(Bool.self, forKey: .banned)
        memberType = try c.decodeIfPresent(Int.self, forKey: .memberType)
        followersCount = try c.decodeIfPresent(Int.self, forKey: .followersCount)
        likesCount = try c.decodeIfPresent(Int.self, forKey: .likesCount)
        isAdmin = try c.decodeIfPresent(Bool.self, forKey: .isAdmin)
        languageIsoCode = try c.decodeIfPresent(String.self, forKey: .languageIsoCode)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        country = try c.decodeIfPresent(String.self, forKey: .country)
        followed = try c.decodeIfPresent(Bool.self, forKey: .followed)
    }

    var displayTitle: String {
        let parts = [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }
        if parts.isEmpty == false { return parts.joined(separator: " ") }
        if let u = username, u.isEmpty == false { return u }
        return id.isEmpty ? "Profile" : id
    }

    var preferredAvatarURL: URL? {
        let s = avatarUrls?.medium ?? avatarUrls?.large ?? avatarUrls?.small
        guard let s, let u = URL(string: s) else { return nil }
        return u
    }
}
