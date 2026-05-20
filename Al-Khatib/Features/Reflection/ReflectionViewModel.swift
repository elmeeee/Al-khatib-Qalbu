//
//  ReflectionViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Observation

enum ReflectPostsSegment: String, CaseIterable, Identifiable, Equatable {
    case feed
    case myPosts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feed: return "Reflect"
        case .myPosts: return "My Reflect"
        }
    }
}

@MainActor
@Observable
final class ReflectionViewModel {
    var selectedSegment: ReflectPostsSegment = .feed
    var posts: [ReflectFeedPost] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    private(set) var currentPage = 1
    private(set) var totalPages = 1

    var shareText: String = ""
    var shareVerseKey: String = ""
    var shareError: String?
    var isPostingShare = false

    private let reflect: ReflectRepository
    private let pageSize = 20
    private var loadTask: Task<Void, Never>?

    init(reflect: ReflectRepository) {
        self.reflect = reflect
    }

    /// Called when user taps a segment — always fetches from the matching API.
    func onSegmentChanged(to segment: ReflectPostsSegment) {
        loadTask?.cancel()
        selectedSegment = segment
        posts = []
        errorMessage = nil
        currentPage = 1
        totalPages = 1
        loadTask = Task { await loadPosts(refresh: true, force: true) }
    }

    func loadPosts(refresh: Bool, force: Bool = false) async {
        if Task.isCancelled { return }

        if refresh {
            if force == false, isLoading { return }
            if posts.isEmpty {
                isLoading = true
            }
            errorMessage = nil
            currentPage = 1
        } else {
            guard isLoadingMore == false, currentPage < totalPages else { return }
            isLoadingMore = true
        }

        let page = refresh ? 1 : currentPage + 1
        let segment = selectedSegment

        defer {
            isLoading = false
            isLoadingMore = false
        }

        do {
            let envelope: ReflectFeedEnvelope
            switch segment {
            case .feed:
                envelope = try await reflect.fetchFeed(page: page, limit: pageSize)
            case .myPosts:
                envelope = try await reflect.fetchMyPosts(page: page, limit: pageSize)
            }

            if Task.isCancelled { return }

            let rows = envelope.data ?? []
            totalPages = max(envelope.pages ?? 1, 1)
            currentPage = envelope.currentPage ?? page
            if refresh {
                posts = rows
            } else {
                posts.append(contentsOf: rows)
            }
            errorMessage = nil
        } catch QFError.missingUserSession {
            if Task.isCancelled { return }
            posts = []
            errorMessage = segment == .myPosts
                ? "Sign in to see your reflections."
                : "Sign in to see the Reflect feed."
        } catch {
            if Task.isCancelled { return }
            if refresh { posts = [] }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func showMyPostsAfterPublish() {
        onSegmentChanged(to: .myPosts)
    }

    func loadMoreIfNeeded(currentPost: ReflectFeedPost) {
        guard isLoading == false, isLoadingMore == false else { return }
        guard currentPage < totalPages else { return }
        guard let index = posts.firstIndex(where: { $0.id == currentPost.id }) else { return }
        guard index >= posts.count - 2 else { return }
        Task { await loadPosts(refresh: false) }
    }

    func prepareShareReflection(body: String, verseKey: String) {
        shareText = body
        shareVerseKey = verseKey
    }

    func clearShareReflection() {
        shareText = ""
        shareVerseKey = ""
        shareError = nil
    }

    func postShareReflection(authorId: String) async -> String {
        let t = shareText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.isEmpty == false else {
            shareError = "No reflection text."
            return "Nothing to save."
        }
        guard t.count >= 6 else {
            shareError = "Reflection must be at least 6 characters."
            return "Text is too short."
        }
        guard authorId.isEmpty == false else {
            shareError = "Please sign in first."
            return "Sign in to post a reflection."
        }

        isPostingShare = true
        defer { isPostingShare = false }

        do {
            _ = try await reflect.createPostFromShare(
                body: t,
                verseKey: shareVerseKey.isEmpty ? nil : shareVerseKey,
                authorId: authorId,
                languageId: nil
            )
            clearShareReflection()
            NotificationCenter.default.post(name: .reflectDidPost, object: nil)
            return "Reflection posted!"
        } catch QFError.missingUserSession {
            shareError = "Please sign in first."
            return "Sign in to post a reflection."
        } catch {
            shareError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return "Post failed: \(shareError ?? "Unknown error")"
        }
    }
}

extension Notification.Name {
    static let reflectDidPost = Notification.Name("reflectDidPost")
    static let reflectTabDidBecomeActive = Notification.Name("reflectTabDidBecomeActive")
}
