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

    var body: some View {
        ZStack {
            Color.Theme.offWhite.ignoresSafeArea()

            if verseState.isRefreshingProfile && verseState.isLoggedIn == false {
                LoadingSkeleton()
            } else if verseState.isLoggedIn {
                if let m = vm {
                    mainContent(m)
                } else {
                    LoadingSkeleton()
                }
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
                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                    .padding(.top, 16)
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
                    await ensureViewModelAndLoad()
                } else {
                    vm = nil
                }
            }
        }
        .task {
            guard verseState.isLoggedIn else { return }
            await ensureViewModelAndLoad()
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
    }

    private func ensureViewModelAndLoad() async {
        if let c = container, vm == nil {
            vm = ReflectionViewModel(reflect: c.reflect)
        }
        await vm?.loadPosts(refresh: true)
    }

    @ViewBuilder
    private func mainContent(_ m: ReflectionViewModel) -> some View {
        @Bindable var bindable = m

        ZStack {
            Color.Theme.offWhite.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar(bindable)

                if bindable.isLoading && bindable.posts.isEmpty {
                    postsLoadingBody
                } else if let e = bindable.errorMessage, bindable.posts.isEmpty {
                    postsErrorBody(e, segment: bindable.selectedSegment) {
                        bindable.onSegmentChanged(to: bindable.selectedSegment)
                    }
                } else if bindable.posts.isEmpty {
                    emptyPostsBody(segment: bindable.selectedSegment)
                } else {
                    postsList(bindable)
                }
            }
        }
        .sheet(isPresented: $showShareEditor) {
            ShareReflectionSheet(verseState: verseState, vm: bindable) { message, isError in
                shareToast = message
                shareToastIsError = isError
                withAnimation { showShareToast = true }
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    withAnimation { showShareToast = false }
                }
            }
        }
    }

    private func headerBar(_ bindable: ReflectionViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Reflect")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color.Theme.deepEmerald)
                Spacer()

                Button {
                    bindable.onSegmentChanged(to: bindable.selectedSegment)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.Theme.deepEmerald)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
            }

            ReflectPostsSegmentedControl(
                selection: Binding(
                    get: { bindable.selectedSegment },
                    set: { bindable.onSegmentChanged(to: $0) }
                )
            )
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var postsLoadingBody: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    FeedPostSkeletonCard()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func postsErrorBody(
        _ error: String,
        segment: ReflectPostsSegment,
        retry: @escaping () -> Void
    ) -> some View {
        ContentUnavailableView {
            Label(
                segment == .myPosts ? "Couldn't load your posts" : "Couldn't load feed",
                systemImage: "wifi.exclamationmark"
            )
        } description: {
            Text(error)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        } actions: {
            Button("Try again", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(Color.Theme.deepEmerald)
        }
    }

    @ViewBuilder
    private func emptyPostsBody(segment: ReflectPostsSegment) -> some View {
        ContentUnavailableView {
            Label(
                segment == .myPosts ? "No posts yet" : "No reflections yet",
                systemImage: "square.and.pencil"
            )
        } description: {
            Text(
                segment == .myPosts
                    ? "Your published reflections will appear here."
                    : "Community reflections will appear here."
            )
        }
    }

    private func postsList(_ bindable: ReflectionViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(bindable.posts) { post in
                    FeedPostCard(post: post)
                }

                if bindable.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, 12)
                } else if bindable.currentPage < bindable.totalPages {
                    Button {
                        Task { await bindable.loadPosts(refresh: false) }
                    } label: {
                        Text("Load more")
                            .font(.subheadline.bold())
                            .foregroundColor(Color.Theme.deepEmerald)
                    }
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .refreshable {
            await bindable.loadPosts(refresh: true, force: true)
        }
    }
}

// MARK: - Segmented control (explicit tap → API fetch)

private struct ReflectPostsSegmentedControl: View {
    @Binding var selection: ReflectPostsSegment

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ReflectPostsSegment.allCases) { segment in
                let isSelected = selection == segment
                Button {
                    selection = segment
                } label: {
                    Text(segment.title)
                        .font(.subheadline.weight(isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? Color.Theme.deepEmerald : Color.primary.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.Theme.pureWhite)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.Theme.softGrey.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

// MARK: - Compose sheet (manual post from verse context)

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

// MARK: - Feed Post Card

struct FeedPostCard: View {
    let post: ReflectFeedPost

    private var formattedDate: String {
        guard let createdAt = post.createdAt else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: createdAt) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: createdAt) else { return createdAt }
            return date.relativeFormatted
        }
        return date.relativeFormatted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                if let avatarURL = post.author?.avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        default:
                            authorPlaceholder
                        }
                    }
                } else {
                    authorPlaceholder
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(post.author?.displayName ?? "Contributor")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        if post.author?.verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color.Theme.deepEmerald)
                        }
                    }
                    Text(formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let postType = post.postTypeName {
                    Text(postType)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.Theme.deepEmerald)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.Theme.deepEmerald.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            if let ref = post.references?.first,
               let key = ref.verseKey,
               key.isEmpty == false {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.Theme.gold)
                    Text(VerseKeyFormat.humanLabel(for: key))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.Theme.deepEmerald)
                }
            }

            if let body = post.body, body.isEmpty == false {
                ReflectPostText(text: body)
            }

            if let tags = post.tags, tags.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                            if let name = tag.name {
                                Text("#\(name)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.Theme.deepEmerald.opacity(0.8))
                            }
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 0) {
                actionChip(
                    icon: post.isLiked == true ? "heart.fill" : "heart",
                    count: post.likesCount,
                    isActive: post.isLiked == true
                )
                Spacer()
                actionChip(
                    icon: "bubble.right",
                    count: post.commentsCount,
                    isActive: false
                )
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.Theme.softGrey.opacity(0.5), lineWidth: 1))
    }

    private var authorPlaceholder: some View {
        Circle()
            .fill(Color.Theme.softGrey.opacity(0.4))
            .frame(width: 36, height: 36)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.Theme.softGrey)
            )
    }

    @ViewBuilder
    private func actionChip(icon: String, count: Int?, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isActive ? Color.Theme.deepEmerald : .secondary)
            if let c = count, c > 0 {
                Text("\(c)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

struct FeedPostSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.Theme.softGrey.opacity(0.3))
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonBar(width: 100, height: 12, cornerRadius: 6)
                    SkeletonBar(width: 60, height: 10, cornerRadius: 5)
                }
                Spacer()
            }
            ForEach(0..<3, id: \.self) { i in
                SkeletonBar(width: i == 2 ? 200 : nil, height: 14, cornerRadius: 6)
            }
            Divider()
            HStack {
                SkeletonBar(width: 50, height: 12, cornerRadius: 6)
                Spacer()
                SkeletonBar(width: 50, height: 12, cornerRadius: 6)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.Theme.softGrey.opacity(0.5), lineWidth: 1))
    }
}

extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
