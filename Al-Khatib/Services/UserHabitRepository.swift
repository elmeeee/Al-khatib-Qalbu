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
    private let appGroup: String

    init(client: QFApiClient, appGroup: String) {
        self.client = client
        self.appGroup = appGroup
    }

    private var userDefaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    /// Current “active” streak length (best-effort: first active streak in the page, else max days).
    func fetchQuranStreak() async throws -> Int {
        if let currentDays = try? await fetchAuthV1CurrentStreakDays(), currentDays > 0 {
            persistWidgetStreak(currentDays)
            return currentDays
        }
        if let authStreak = try? await fetchAuthV1StreakDays(), authStreak > 0 {
            persistWidgetStreak(authStreak)
            return authStreak
        }
        return userDefaults.integer(forKey: StreakWidgetKeys.streak)
    }

    /// Per-user streak/activity is authorized for the **user OAuth JWT**; M2M `content` token is a fallback (QF curl style).
    func fetchAuthV1StreakDays() async throws -> Int {
        let q = [
            URLQueryItem(name: "type", value: "QURAN"),
            URLQueryItem(name: "status", value: "ACTIVE"),
            URLQueryItem(name: "first", value: "20"),
            URLQueryItem(name: "orderBy", value: "startDate"),
            URLQueryItem(name: "sortOrder", value: "desc")
        ]
        do {
            let envelope: AuthV1StreaksListEnvelope = try await client.send(
                UserHabitGetEndpoint.streaksUser(query: q)
            )
            if let n = Self.streakDaysFromList(envelope) { return n }
        } catch QFError.missingUserSession {
            throw QFError.missingUserSession
        } catch {
            guard Self.isScopeOr403(error) else { throw error }
            throw QFError.missingUserSession
        }
        // Note: Removed client token fallback as /auth/v1/streaks now requires user authentication
        throw QFError.missingUserSession
    }

    /// GET .../streaks/current-streak-days?type=QURAN
    func fetchAuthV1CurrentStreakDays() async throws -> Int {
        let q = [URLQueryItem(name: "type", value: "QURAN")]
        let timezone = TimeZone.current.identifier
        let headers = ["x-timezone": timezone]
        do {
            let envelope: AuthV1CurrentStreakEnvelope = try await client.send(
                UserHabitGetEndpoint.currentStreakUser(query: q, headers: headers)
            )
            return envelope.data?.days ?? 0
        } catch QFError.missingUserSession {
            throw QFError.missingUserSession
        } catch {
            guard Self.isScopeOr403(error) else { throw error }
            throw QFError.missingUserSession
        }
    }

    /// GET .../auth/v1/activity-days (calendar/history)
    func fetchAuthV1ActivityDays(
        from: String? = nil,
        to: String? = nil,
        type: String? = "QURAN",
        dateOrderBy: String = "desc",
        first: Int = 20
    ) async throws -> [AuthV1ActivityDay] {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "dateOrderBy", value: dateOrderBy),
            URLQueryItem(name: "first", value: String(min(max(first, 1), 20)))
        ]
        if let from, from.isEmpty == false { query.append(URLQueryItem(name: "from", value: from)) }
        if let to, to.isEmpty == false { query.append(URLQueryItem(name: "to", value: to)) }
        if let type, type.isEmpty == false { query.append(URLQueryItem(name: "type", value: type)) }
        let timezone = TimeZone.current.identifier
        do {
            let response: AuthV1ActivityDaysEnvelope = try await client.send(
                UserHabitGetEndpoint.activityDaysUser(
                    query: query,
                    headers: ["x-timezone": timezone]
                )
            )
            return response.data ?? []
        } catch QFError.missingUserSession {
            return []
        } catch {
            guard Self.isScopeOr403(error) else { throw error }
            return []
        }
    }

    func postAuthV1ActivityDay(
        date: String,
        type: String,
        seconds: Int,
        ranges: [String],
        mushafId: Int
    ) async throws -> Bool {
        let body = AuthV1ActivityDayInput(
            date: date,
            type: type,
            seconds: seconds,
            ranges: ranges,
            mushafId: mushafId
        )
        do {
            let timezone = TimeZone.current.identifier
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let endpoint = UserHabitPostActivityDaysEndpoint(
                bodyData: try encoder.encode(body),
                headers: ["x-timezone": timezone]
            )
            let response: AuthV1ActivityDayEnvelope = try await client.send(endpoint)
            return response.success ?? true
        } catch QFError.missingUserSession {
            return false
        } catch {
            guard Self.isScopeOr403(error) else { throw error }
            return false
        }
    }

    private static func streakDaysFromList(_ envelope: AuthV1StreaksListEnvelope) -> Int? {
        guard let rows = envelope.data else { return nil }
        if let active = rows.first(where: { $0.status == "ACTIVE" }), let d = active.days, d > 0 { return d }
        let maxDays = rows.compactMap(\.days).max()
        return maxDays.flatMap { $0 > 0 ? $0 : nil }
    }

    private static func isScopeOr403(_ error: Error) -> Bool {
        let m = error.localizedDescription.lowercased()
        return m.contains("insufficient_scope") || m.contains("http 403") || m.contains("\"type\":\"insufficient_scope\"")
    }

    private func persistWidgetStreak(_ n: Int) {
        userDefaults.set(n, forKey: StreakWidgetKeys.streak)
        userDefaults.set(Date().timeIntervalSince1970, forKey: StreakWidgetKeys.streakUpdatedAt)
    }

    /// Log a reflection day; adjust `type` if your org maps reflections to a custom activity.
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

    func fetchMyProfile() async throws -> UserProfilePayload {
        try await client.send(ReflectEndpoint.profile)
    }

    /// Safe edit-profile diagnostics: PATCH with same `postAs` value, expecting `{ success: true }`.
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

enum StreakWidgetKeys {
    static let streak = "widget.streak.current"
    static let streakUpdatedAt = "widget.streak.updatedAt"
}

private struct EditProfileInput: Encodable, Sendable {
    let postAs: Bool
}

private struct EditProfileResponse: Decodable, Sendable {
    let success: Bool
}

private struct AuthV1StreaksListEnvelope: Decodable, Sendable {
    let success: Bool?
    let data: [StreakRecord]?
}

private struct AuthV1CurrentStreakEnvelope: Decodable, Sendable {
    let success: Bool?
    let data: AuthV1CurrentStreakData?
}

private struct AuthV1CurrentStreakData: Decodable, Sendable {
    let days: Int?
}

private struct AuthV1ActivityDaysEnvelope: Decodable, Sendable {
    let success: Bool?
    let data: [AuthV1ActivityDay]?
}

struct AuthV1ActivityDay: Decodable, Sendable {
    let id: String?
    let date: String?
    let progress: Double?
    let type: String?
    let seconds: Int?
    let secondsRead: Int?
    let ranges: [String]?
    let pagesRead: Double?
    let versesRead: Int?
    let manuallyAddedSeconds: Int?
    let dailyTargetPages: Double?
    let dailyTargetSeconds: Int?
    let dailyTargetRanges: [String]?
    let remainingDailyTargetRanges: [String]?
    let mushafId: Int?
}

private struct AuthV1ActivityDayInput: Encodable, Sendable {
    let date: String
    let type: String
    let seconds: Int
    let ranges: [String]
    let mushafId: Int
}

private struct AuthV1ActivityDayEnvelope: Decodable, Sendable {
    let success: Bool?
}
