//
//  TodayReflectionPublishViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class TodayReflectionPublishViewModel {
    var isPosting = false
    var statusMessage: String?
    var statusIsError = false
    var showStatus = false

    func publish(
        verse: RandomAyahPayload,
        shareProvider: TodayShareProviding,
        verseState: TodayVerseState,
        container: AppContainer
    ) async -> PublishOutcome {
        isPosting = true
        defer { isPosting = false }

        await verseState.ensureProfileLoaded(container: container)

        if verseState.isLoggedIn == false {
            await verseState.signIn(container: container)
        }
        guard verseState.isLoggedIn, let authorId = verseState.userId, authorId.isEmpty == false else {
            return .needsSignIn
        }

        let body = shareProvider.cachedShareText(for: verse) ?? shareProvider.quickReflectionText(for: verse)
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 6 else {
            return .failed(message: "Reflection is too short to publish.")
        }

        let verseKey = Self.resolvedAyahKey(for: verse)
        let day = Self.todayKey()
        let idempotencyKey = verseKey.map { "reflect:\($0):\(day)" }

        do {
            _ = try await container.reflect.createReflectionPost(
                body: trimmed,
                verseKey: verseKey,
                authorId: authorId,
                idempotencyKey: idempotencyKey
            )
            verseState.notifyFeedDidUpdate()
            verseState.requestReflect()
            return .published
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return .failed(message: message)
        }
    }

    func presentStatus(_ message: String, isError: Bool) {
        statusMessage = message
        statusIsError = isError
        showStatus = true
    }

    func hideStatusAfterDelay(seconds: TimeInterval = 3) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        showStatus = false
    }

    private static func resolvedAyahKey(for verse: RandomAyahPayload) -> String? {
        guard let key = verse.verseKey, key.isEmpty == false else { return nil }
        return key
    }

    private static func todayKey() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        return fmt.string(from: .now)
    }
}
