//
//  QuranPlaybackActivity.swift
//  Al-Khatib
//
//  Created by Elmee on 26/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import ActivityKit
import Foundation

/// ActivityAttributes describing Quran audio playback.
/// Shared between the main app (which starts/updates the activity)
/// and the widget extension (which renders it).
struct QuranPlaybackAttributes: ActivityAttributes {
    /// Static context that does not change during the activity's lifetime.
    let surahName: String
    let reciterName: String

    /// Dynamic state that updates as playback progresses.
    struct ContentState: Codable, Hashable {
        let verseLabel: String
        let isPlaying: Bool
        let progress: Double
        let currentVerse: Int
        let totalVerses: Int
    }
}
