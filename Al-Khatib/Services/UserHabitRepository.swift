//
//  UserHabitRepository.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct UserHabitRepository: Sendable {
    private let client: QFApiClient

    init(client: QFApiClient) {
        self.client = client
    }

    func logQuranActivityForToday(verses: Int) async throws {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        let day = fmt.string(from: .now)
        let tz = TimeZone.current.identifier
        let body = ActivityDayInput(
            type: "QURAN",
            day: day,
            timezone: tz,
            versesRead: verses
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let endpoint = ReflectPostEndpoint(
            path: ReflectEndpoint.activityDays.path,
            bodyData: try encoder.encode(body),
            idempotencyKey: "activity:\(day)"
        )
        let _: ActivityDayEnvelope = try await client.send(endpoint)
    }

    func fetchMyProfile(force: Bool = false) async throws -> UserProfilePayload {
        if force == false, let cached = await APICache.Profile.shared.cached() {
            return cached
        }
        return try await APICoalescer.profile.run {
            if force == false, let cached = await APICache.Profile.shared.cached() {
                return cached
            }
            let profile: UserProfilePayload = try await self.client.send(ReflectEndpoint.profile)
            await APICache.Profile.shared.store(profile)
            return profile
        }
    }

    func patchMyProfileNoop(postAs: Bool) async throws -> Bool {
        let body = EditProfileInput(postAs: postAs)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let endpoint = ReflectPatchEndpoint(
            path: ReflectEndpoint.profile.path,
            bodyData: try encoder.encode(body)
        )
        let res: EditProfileResponse = try await client.send(endpoint)
        return res.success
    }
}

private struct EditProfileInput: Encodable, Sendable {
    let postAs: Bool
}

private struct EditProfileResponse: Decodable, Sendable {
    let success: Bool
}
