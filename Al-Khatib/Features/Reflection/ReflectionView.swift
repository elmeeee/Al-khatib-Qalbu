//
//  ReflectionView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectionView: View {
    @Environment(\.appContainer) private var container
    @State private var vm: ReflectionViewModel?
    @State private var showShareEditor = false
    @State private var shareToast = ""
    @State private var showShareToast = false
    @State private var shareToastIsError = false

    let verseState: TodayVerseState
    var isTabSelected: Bool = false

    @State private var hasAccessToken = false

    var body: some View {
        ZStack {
            Group {
                if canShowReflectFeed || verseState.isLoggedIn {
                    LinearGradient(
                        colors: [
                            Color(hex: "#0B3D34"),
                            Color.Theme.deepEmerald,
                            Color(hex: "#051F1A")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.Theme.offWhite
                }
            }
            .ignoresSafeArea()

            if shouldShowSignInPrompt {
                SignInPromptView(
                    title: "Sign in to Reflect",
                    message: "Connect your Quran Reflect account to browse reflections and share your own.",
                    isLoading: verseState.isLoggingIn
                ) {
                    Task { await verseState.signIn(container: container) }
                }
            } else if canShowReflectFeed {
                if let m = vm {
                    ReflectReelFeedView(viewModel: m)
                } else {
                    reelBootLoading
                }
            } else if verseState.hasResolvedSession == false && hasAccessToken == false {
                LoadingSkeleton()
            } else if verseState.hasResolvedSession {
                SignInPromptView(
                    title: "Sign in to Reflect",
                    message: "Connect your Quran Reflect account to browse reflections and share your own.",
                    isLoading: verseState.isLoggingIn
                ) {
                    Task { await verseState.signIn(container: container) }
                }
            } else {
                LoadingSkeleton()
            }
        }
        .overlay(alignment: .top) {
            if showShareToast {
                Text(shareToast)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(shareToastIsError ? Color.red : Color.Theme.deepEmerald)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.25), radius: 6, y: 2)
                    .padding(.top, 56)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                if verseState.isLoggedIn == false {
                    vm = nil
                }
            }
        }
        .onChange(of: verseState.isLoggedIn) { _, loggedIn in
            Task {
                if loggedIn {
                    await bootstrapFeed()
                } else {
                    vm = nil
                    await refreshAccessTokenFlag()
                }
            }
        }
        .task {
            await refreshAccessTokenFlag()
            await bootstrapFeed()
        }
        .onChange(of: isTabSelected) { _, selected in
            guard selected else { return }
            Task { await bootstrapFeed(force: true) }
        }
        .onChange(of: verseState.feedNeedsRefresh) { _, needsRefresh in
            guard needsRefresh, verseState.isLoggedIn else { return }
            vm?.showMyPostsAfterPublish()
            verseState.didRefreshFeed()
        }
        .onChange(of: verseState.shouldNavigateToReflect) { _, shouldNavigate in
            if shouldNavigate {
                verseState.didNavigateToReflect()
                verseState.preparedShareText = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .reflectDidPost)) { _ in
            guard verseState.isLoggedIn else { return }
            vm?.showMyPostsAfterPublish()
        }
        .onReceive(NotificationCenter.default.publisher(for: .reflectTabDidBecomeActive)) { _ in
            Task { await bootstrapFeed(force: true) }
        }
    }

    private var reelBootLoading: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#0B3D34"),
                    Color.Theme.deepEmerald,
                    Color(hex: "#051F1A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            ProgressView()
                .tint(.white)
                .scaleEffect(1.1)
        }
    }

    private var shouldShowSignInPrompt: Bool {
        verseState.hasResolvedSession && verseState.isLoggedIn == false && hasAccessToken == false
    }

    private var canShowReflectFeed: Bool {
        verseState.isLoggedIn || hasAccessToken
    }

    private func refreshAccessTokenFlag() async {
        guard let container else {
            hasAccessToken = false
            return
        }
        hasAccessToken = await container.userSession.hasUserAccessToken()
    }

    private func bootstrapFeed(force: Bool = false) async {
        let hasAccess = await hasToken()
        guard canShowReflectFeed || hasAccess else { return }
        if let c = container, vm == nil {
            vm = ReflectionViewModel(reflect: c.reflect)
        }
        await vm?.loadPosts(refresh: true, force: force)
    }

    private func hasToken() async -> Bool {
        guard let container else { return false }
        return await container.userSession.hasUserAccessToken()
    }
}

struct ShareReflectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let verseState: TodayVerseState
    let vm: ReflectionViewModel
    let onComplete: (String, Bool) -> Void

    @State private var text = ""
    @State private var verseKey = ""
    @State private var verseLabel = ""
    @State private var isPosting = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.offWhite.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        verseBanner
                        editorCard

                        if let e = vm.shareError {
                            Text(e)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button {
                            Task { await post() }
                        } label: {
                            HStack(spacing: 8) {
                                if isPosting {
                                    ProgressView().tint(.white)
                                }
                                Text("Post Reflection")
                                    .font(.headline)
                            }
                        }
                        .buttonStyle(.primaryFlat)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).count < 6 || isPosting)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Reflect on this Verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .toolbarBackground(Color.Theme.pureWhite, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            if let preparedText = verseState.preparedShareText,
               let preparedKey = verseState.activeVerseKey {
                text = preparedText
                verseKey = preparedKey
                verseLabel = verseState.activeVerseLabel ?? preparedKey
            } else if let key = verseState.activeVerseKey,
                      let label = verseState.activeVerseLabel {
                verseKey = key
                verseLabel = label
            }
            vm.prepareShareReflection(body: text, verseKey: verseKey)
        }
    }

    private var verseBanner: some View {
        Group {
            if verseLabel.isEmpty == false {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.Theme.gold)
                        Text("Reflecting on")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Text(verseLabel)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.Theme.deepEmerald)
                    if let arabic = verseState.activeArabicSnippet, arabic.isEmpty == false {
                        Text(arabic)
                            .font(AlKhatibTypography.quranArabic(size: 19))
                            .multilineTextAlignment(.trailing)
                            .environment(\.layoutDirection, .rightToLeft)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.Theme.deepEmerald.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.Theme.deepEmerald.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your Reflection")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.Theme.deepEmerald)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 4)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("What does this ayah mean to you today?")
                        .foregroundColor(Color.Theme.softGrey)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.body)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 160)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.Theme.softGrey, lineWidth: 1))
    }

    @MainActor
    private func post() async {
        guard let authorId = verseState.userId, authorId.isEmpty == false else {
            onComplete("Sign in to post a reflection.", true)
            return
        }
        isPosting = true
        vm.prepareShareReflection(body: text, verseKey: verseKey)
        let msg = await vm.postShareReflection(authorId: authorId)
        isPosting = false
        let isError = vm.shareError != nil
        onComplete(msg, isError)
        if vm.shareError == nil {
            dismiss()
        }
    }
}

extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
