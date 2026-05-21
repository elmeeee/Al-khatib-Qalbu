//
//  ReflectionView.swift
//  Al-Khatib
//

import SwiftUI

struct ReflectionView: View {
    @Environment(\.appContainer) private var container
    @State private var tabViewModel = ReflectionTabViewModel()
    @State private var shareToast = ""
    @State private var showShareToast = false
    @State private var shareToastIsError = false

    let verseState: TodayVerseState
    var isTabSelected: Bool = false

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            screenContent

            shareToastOverlay
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                tabViewModel.sync(verseState: verseState)
                await tabViewModel.handleSessionChange(
                    container: container,
                    verseState: verseState,
                    isTabSelected: isTabSelected
                )
            }
        }
        .onChange(of: verseState.isLoggedIn) { _, loggedIn in
            Task {
                await tabViewModel.handleLoggedInChange(
                    container: container,
                    verseState: verseState,
                    isTabSelected: isTabSelected,
                    loggedIn: loggedIn
                )
            }
        }
        .task(id: isTabSelected) {
            guard isTabSelected, let container else { return }
            tabViewModel.sync(verseState: verseState)
            await tabViewModel.openTab(container: container, verseState: verseState)
        }
        .onChange(of: verseState.feedNeedsRefresh) { _, needsRefresh in
            guard needsRefresh, verseState.isLoggedIn else { return }
            tabViewModel.feedViewModel?.showMyPostsAfterPublish()
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
            tabViewModel.feedViewModel?.showMyPostsAfterPublish()
        }
        .onAppear {
            tabViewModel.sync(verseState: verseState)
        }
    }

    @ViewBuilder
    private var screenContent: some View {
        switch tabViewModel.screen {
        case .signIn:
            SignInPromptView(
                title: "Sign in to Reflect",
                message: "Connect your Quran Reflect account to browse reflections and share your own.",
                isLoading: verseState.isLoggingIn
            ) {
                Task { await verseState.signIn(container: container) }
            }
        case .bootLoading:
            reelBootLoading
        case .feed:
            if let feedViewModel = tabViewModel.feedViewModel {
                ReflectReelFeedView(viewModel: feedViewModel)
            } else {
                reelBootLoading
            }
        case .sessionLoading:
            LoadingSkeleton()
        }
    }

    @ViewBuilder
    private var background: some View {
        if tabViewModel.canShowReflectFeed || verseState.isLoggedIn {
            LinearGradient(
                colors: [
                    Color.Token.forestDark,
                    Color.Theme.deepEmerald,
                    Color.Token.forestDeeper
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.Theme.offWhite
        }
    }

    private var reelBootLoading: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.Token.forestDark,
                    Color.Theme.deepEmerald,
                    Color.Token.forestDeeper
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

    @ViewBuilder
    private var shareToastOverlay: some View {
        if showShareToast {
            HStack(spacing: 8) {
                Image(systemName: shareToastIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text(shareToast)
                    .font(.subheadline.bold())
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(.ultraThinMaterial)
            .background(shareToastIsError ? Color.red.opacity(0.3) : Color.Theme.deepEmerald.opacity(0.3))
            .foregroundColor(.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
            .shadow(color: Color.black.opacity(0.25), radius: 6, y: 2)
            .padding(.top, 56)
            .frame(maxHeight: .infinity, alignment: .top)
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(1)
        }
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
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.Theme.deepEmerald, Color.Token.tealDark],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .foregroundColor(.white)
                        }
                        .buttonStyle(PillPressStyle())
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).count < 6 || isPosting)
                        .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).count < 6 ? 0.5 : 1.0)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.Theme.gold)
                Text(verseLabel.isEmpty ? "Quran verse" : verseLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.Theme.deepEmerald)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.Theme.deepEmerald.opacity(0.15))
            )
        }
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your reflection")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            TextEditor(text: $text)
                .frame(minHeight: 160)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(Color.Theme.pureWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.Theme.deepEmerald.opacity(0.15), lineWidth: 1)
                )
        }
    }

    private func post() async {
        isPosting = true
        defer { isPosting = false }
        guard let authorId = verseState.userId, authorId.isEmpty == false else {
            onComplete("Please sign in to publish a reflection.", true)
            dismiss()
            return
        }
        let message = await vm.postShareReflection(authorId: authorId)
        let isError = vm.shareError != nil
        onComplete(message, isError)
        dismiss()
    }
}
