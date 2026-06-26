//
//  LiveActivityManager.swift
//  Al-Khatib
//
//  Created by Elmee on 26/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import ActivityKit
import Foundation

/// Manages the lifecycle of the Quran playback Live Activity.
/// This lives in the main app and handles start/update/end.
@MainActor
final class LiveActivityManager {

    private var currentActivity: Activity<QuranPlaybackAttributes>?

    /// Start a new Live Activity for Quran playback.
    func startActivity(
        surahName: String,
        reciterName: String,
        verseLabel: String,
        currentVerse: Int,
        totalVerses: Int
    ) {
        // End any existing activity first
        endActivity()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = QuranPlaybackAttributes(
            surahName: surahName,
            reciterName: reciterName
        )
        let state = QuranPlaybackAttributes.ContentState(
            verseLabel: verseLabel,
            isPlaying: true,
            progress: totalVerses > 0 ? Double(currentVerse) / Double(totalVerses) : 0,
            currentVerse: currentVerse,
            totalVerses: totalVerses
        )
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            // Live Activity not available — silently degrade
        }
    }

    /// Update the current Live Activity with new playback state.
    func updateActivity(
        verseLabel: String,
        isPlaying: Bool,
        currentVerse: Int,
        totalVerses: Int,
        progress: Double
    ) {
        guard let activity = currentActivity else { return }

        let state = QuranPlaybackAttributes.ContentState(
            verseLabel: verseLabel,
            isPlaying: isPlaying,
            progress: progress,
            currentVerse: currentVerse,
            totalVerses: totalVerses
        )
        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await activity.update(content)
        }
    }

    /// End the current Live Activity.
    func endActivity() {
        guard let activity = currentActivity else { return }

        let finalState = QuranPlaybackAttributes.ContentState(
            verseLabel: "",
            isPlaying: false,
            progress: 1.0,
            currentVerse: 0,
            totalVerses: 0
        )
        let content = ActivityContent(state: finalState, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}
