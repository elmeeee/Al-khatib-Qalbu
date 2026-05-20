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
        case .feed: return "All Reflect"
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
    private let pageSize = 8
    /// Cap in-memory post payloads (bodies + metadata) when users page deep in the reel.
    private let maxPostsKept = 72
    /// Clears Reflect session (Keychain + caches) so UI returns to sign-in when API returns 401/403.
    var onSessionInvalidated: (@MainActor () -> Void)?
    private var loadTask: Task<Void, Never>?
    private var loadGeneration: UInt = 0
    private var togglingLikePostIDs: Set<String> = []

    init(reflect: ReflectRepository) {
        self.reflect = reflect
    }

    func onSegmentChanged(to segment: ReflectPostsSegment) {
        selectedSegment = segment
        posts = []
        errorMessage = nil
        currentPage = 1
        totalPages = 1
        scheduleLoad(refresh: true, force: true)
    }

    func scheduleLoad(refresh: Bool, force: Bool = false) {
        loadTask?.cancel()
        loadGeneration &+= 1
        let generation = loadGeneration
        loadTask = Task {
            await loadPosts(refresh: refresh, force: force, generation: generation)
        }
    }

    func loadPosts(refresh: Bool, force: Bool = false, generation: UInt? = nil) async {
        if Task.isCancelled { return }
        if let generation, generation != loadGeneration { return }

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
            if generation == nil || generation == loadGeneration {
                isLoading = false
                isLoadingMore = false
            }
        }

        do {
            let envelope: ReflectFeedEnvelope
            switch segment {
            case .feed:
                envelope = try await reflect.fetchFeed(page: page, limit: pageSize, force: force)
            case .myPosts:
                envelope = try await reflect.fetchMyPosts(page: page, limit: pageSize, force: force)
            }

            if Task.isCancelled { return }
            if let generation, generation != loadGeneration { return }

            let rows = envelope.data ?? []
            totalPages = max(envelope.pages ?? 1, 1)
            currentPage = envelope.currentPage ?? page
            if refresh {
                posts = rows
            } else {
                posts.append(contentsOf: rows)
                trimPostsIfNeeded()
            }
            errorMessage = nil
        } catch QFError.missingUserSession {
            if Task.isCancelled { return }
            if let generation, generation != loadGeneration { return }
            await handleReflectAuthenticationFailure()
        } catch {
            if Task.isCancelled { return }
            if let generation, generation != loadGeneration { return }
            if TodayVerseState.isAuthenticationFailure(error) {
                await handleReflectAuthenticationFailure()
                return
            }
            if refresh { posts = [] }
            errorMessage = Self.userFacingMessage(for: error, segment: segment)
        }
    }

    /// Drop feed state and sign out locally so Reflect shows the login prompt (401 / 403 / expired token).
    private func handleReflectAuthenticationFailure() async {
        posts = []
        errorMessage = nil
        currentPage = 1
        totalPages = 1
        onSessionInvalidated?()
    }

    func showMyPostsAfterPublish() {
        onSegmentChanged(to: .myPosts)
    }

    private func trimPostsIfNeeded() {
        guard posts.count > maxPostsKept else { return }
        let target = maxPostsKept - pageSize
        let remove = posts.count - target
        guard remove > 0 else { return }
        posts.removeFirst(remove)
    }

    private static func userFacingMessage(for error: Error, segment: ReflectPostsSegment) -> String {
        if case QFError.networkError(let urlError) = error {
            switch urlError.code {
            case .timedOut:
                return "The server took too long to respond. Check your connection and try again."
            case .notConnectedToInternet, .networkConnectionLost:
                return "No internet connection. Connect and try again."
            default:
                break
            }
        }
        let detail = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        if detail.isEmpty {
            return segment == .myPosts
                ? "Could not load your reflections."
                : "Could not load the Reflect feed."
        }
        return detail
    }

    func isTogglingLike(postId: String) -> Bool {
        togglingLikePostIDs.contains(postId)
    }

    func toggleLike(for post: ReflectFeedPost) async {
        guard togglingLikePostIDs.contains(post.id) == false else { return }
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        togglingLikePostIDs.insert(post.id)
        defer { togglingLikePostIDs.remove(post.id) }

        let wasLiked = posts[index].isLiked == true
        let previousCount = posts[index].likesCount ?? 0

        posts[index].isLiked = !wasLiked
        posts[index].likesCount = max(0, previousCount + (wasLiked ? -1 : 1))

        do {
            let liked = try await reflect.toggleLike(postId: post.id)
            posts[index].isLiked = liked
            if liked != !wasLiked {
                posts[index].likesCount = max(0, previousCount + (liked ? 1 : -1))
            }
        } catch QFError.missingUserSession {
            posts[index].isLiked = wasLiked
            posts[index].likesCount = previousCount
            await handleReflectAuthenticationFailure()
        } catch {
            posts[index].isLiked = wasLiked
            posts[index].likesCount = previousCount
            if TodayVerseState.isAuthenticationFailure(error) {
                await handleReflectAuthenticationFailure()
            }
        }
    }

    func loadMoreIfNeeded(currentPost: ReflectFeedPost) {
        guard isLoading == false, isLoadingMore == false else { return }
        guard currentPage < totalPages else { return }
        guard let index = posts.firstIndex(where: { $0.id == currentPost.id }) else { return }
        guard index >= posts.count - 2 else { return }
        scheduleLoad(refresh: false)
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
            shareError = "Please sign in again."
            await handleReflectAuthenticationFailure()
            return "Sign in to post a reflection."
        } catch {
            if TodayVerseState.isAuthenticationFailure(error) {
                shareError = "Please sign in again."
                await handleReflectAuthenticationFailure()
                return "Sign in to post a reflection."
            }
            shareError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return "Post failed: \(shareError ?? "Unknown error")"
        }
    }
}

extension Notification.Name {
    static let reflectDidPost = Notification.Name("reflectDidPost")
}
