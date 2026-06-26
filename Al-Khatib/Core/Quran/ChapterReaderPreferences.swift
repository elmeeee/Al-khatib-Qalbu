//
//  ChapterReaderPreferences.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum ChapterReaderPreferences {
    static let translationIdKey = "chapterReaderTranslationId"
    static let translationNameKey = "chapterReaderTranslationName"

    static let translationDidChangeNotification = Notification.Name("chapterReaderTranslationDidChange")

    static var defaultTranslationId: Int {
        max(AppEndpoints.Runtime.defaultTranslationId, 1)
    }

    static func selectedTranslationId(defaults: UserDefaults = .standard) -> Int {
        let saved = defaults.integer(forKey: translationIdKey)
        return saved > 0 ? saved : defaultTranslationId
    }

    static func selectedTranslationIdQueryValue(defaults: UserDefaults = .standard) -> String {
        String(selectedTranslationId(defaults: defaults))
    }

    static func notifyTranslationDidChange() {
        NotificationCenter.default.post(name: translationDidChangeNotification, object: nil)
    }
}
