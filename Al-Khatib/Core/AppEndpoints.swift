//
//  AppEndpoints.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum AppEndpoints {

    enum Runtime {
        static var apiBase: URL { url(forInfoKey: "QF_API_BASE_URL") }
        static var oauthToken: URL { url(forInfoKey: "QF_OAUTH_TOKEN_URL") }
        static var oauthAuthorize: URL { url(forInfoKey: "QF_OAUTH_AUTHORIZE_URL") }
        static var oauthCallback: URL { url(forInfoKey: "QF_OAUTH_CALLBACK_URL") }
        static var versesWebBase: String { string(forInfoKey: "QF_VERSES_WEB_BASE") }
        static var alAdhanRoot: String { string(forInfoKey: "QF_ALADHAN_ROOT") }
        static var oauthClientId: String { string(forInfoKey: "QF_OAUTH_CLIENT_ID") }
        static var oauthScopes: String { string(forInfoKey: "QF_OAUTH_SCOPES") }
        static var defaultTranslationId: Int { int(forInfoKey: "QF_DEFAULT_TRANSLATION_ID") }

        static var oauthClientSecret: String? {
            optionalString(forInfoKey: "QF_OAUTH_CLIENT_SECRET")
        }

        static func string(forInfoKey key: String) -> String {
            guard let raw = optionalString(forInfoKey: key) else {
                fatalError("Missing \(key) — check Config/Debug.xcconfig or Release.xcconfig")
            }
            return raw
        }

        static func int(forInfoKey key: String) -> Int {
            guard let value = Int(string(forInfoKey: key)) else {
                fatalError("Invalid integer for \(key)")
            }
            return value
        }

        private static func url(forInfoKey key: String) -> URL {
            guard let url = URL(string: string(forInfoKey: key)) else {
                fatalError("Invalid URL for \(key)")
            }
            return url
        }

        private static func optionalString(forInfoKey key: String) -> String? {
            guard let raw = Bundle.main.infoDictionary?[key] as? String,
                  raw.isEmpty == false else {
                return nil
            }
            return raw
        }
    }

    enum External {
        static var versesWebBase: String { Runtime.versesWebBase }
        static var alAdhanRoot: String { Runtime.alAdhanRoot }
    }

    enum Prefix {
        static let contentAPI = "content/api/v4"
        static let quranReflect = "quran-reflect/v1"
        static let authV1 = "auth/v1"
    }

    enum OAuth {
        static let directory = "oauth2"
        static let token = "token"
        static let introspect = "introspect"
    }

    enum Content {
        static let versesRandom = "verses/random"
        static let resourcesRecitations = "resources/recitations"
        static func verseByKey(_ key: String) -> String { "verses/by_key/\(key)" }
        static func hadithsByAyah(_ ayahKey: String) -> String {
            "hadith_references/by_ayah/\(ayahKey)/hadiths"
        }

        static func tafsirByAyah(resourceId: String, ayahKey: String) -> String {
            "tafsirs/\(resourceId)/by_ayah/\(ayahKey)"
        }
    }

    enum Reflect {
        static let activityDays = "activity_days"
        static let posts = "posts"
        static let userProfile = "users/profile"
    }

    enum AuthV1 {
        static let streaks = "streaks"
        static let currentStreakDays = "streaks/current-streak-days"
        static let activityDays = "activity-days"
    }

    enum URLBuilder {
        static func absoluteVerseMediaURLString(from raw: String) -> String {
            if raw.hasPrefix("//") { return "https:\(raw)" }
            if raw.hasPrefix("http") { return raw }
            return "\(External.versesWebBase)/\(raw)"
        }

        /// Builds an Aladhan timings URL using the Muhammadiyah (Majelis Tarjih) calculation method.
        /// - Fajr 18°, Isha 18°, standard Maghrib (sunset)
        /// - School: Shafi'i (Asr shadow factor 1×)
        /// - Tune: ihtiyat offsets matching Muhammadiyah published schedules
        static func alAdhanTimings(
            timestamp: Int,
            latitude: Double,
            longitude: Double
        ) -> URL? {
            var components = URLComponents(string: "\(External.alAdhanRoot)/v1/timings/\(timestamp)")
            components?.queryItems = [
                .init(name: "latitude",       value: "\(latitude)"),
                .init(name: "longitude",      value: "\(longitude)"),
                .init(name: "method",         value: "99"),
                .init(name: "methodSettings", value: "18,null,18"),
                .init(name: "school",         value: "0"),
                .init(name: "tune",           value: "0,2,-1,1,1,3,0,2,0"),
            ]
            return components?.url
        }
    }
}
