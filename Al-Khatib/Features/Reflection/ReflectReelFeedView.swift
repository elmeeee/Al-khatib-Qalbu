//
//  ReflectReelFeedView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

private enum ReflectReelChrome {
    static let gradient = LinearGradient(
        colors: [
            Color.Token.forestDark,
            Color.Token.deepEmerald,
            Color.Token.forestDeeper
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let fillColor = Color.Token.forestDeeper
    static let ambientTeal = Color.Token.teal
    static let ambientGold = Color.Token.goldBright
    static let ambientEmerald = Color.Token.emeraldRich
    static let cardBorderGradient = LinearGradient(
        colors: [
            Color.Token.goldBright.opacity(0.45),
            Color.Token.gold.opacity(0.2),
            Color.Token.goldBright.opacity(0.1),
            Color.white.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardShadowColor = Color.Token.goldBright.opacity(0.12)
}

struct ReflectReelFeedView: View {
    @Bindable var viewModel: ReflectionViewModel
    @Environment(\.appContainer) private var container
    @State private var selectedVerseItem: VerseSheetItem?
    @State private var verseSheetData: SingleVerseResponse?
    @State private var isLoadingVerse = false

    var body: some View {
        ZStack {
            ReflectReelChrome.gradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ReflectFeedTabBar(
                    selection: Binding(
                        get: { viewModel.selectedSegment },
                        set: { viewModel.onSegmentChanged(to: $0) }
                    )
                )

                GeometryReader { geo in
                    let pageHeight = geo.size.height
                    let pageWidth = geo.size.width

                    ZStack {
                        if viewModel.isLoading && viewModel.posts.isEmpty {
                            reelLoadingStack(pageHeight: pageHeight)
                        } else if let error = viewModel.errorMessage, viewModel.posts.isEmpty {
                            reelErrorState(message: error, segment: viewModel.selectedSegment) {
                                viewModel.onSegmentChanged(to: viewModel.selectedSegment)
                            }
                        } else if viewModel.posts.isEmpty {
                            reelEmptyState(segment: viewModel.selectedSegment)
                        } else {
                            reelPager(pageHeight: pageHeight, pageWidth: pageWidth)
                        }

                        if viewModel.isLoading && viewModel.posts.isEmpty == false {
                            VStack {
                                ProgressView()
                                    .tint(.white)
                                    .padding(10)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                Spacer()
                            }
                            .padding(.top, 8)
                        }

                        if viewModel.isLoadingMore {
                            VStack {
                                Spacer()
                                ProgressView()
                                    .tint(.white)
                                    .padding(.bottom, 24)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedVerseItem) { item in
            VerseDetailSheet(
                verseKey: item.id,
                response: verseSheetData,
                isLoading: isLoadingVerse
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
    }

    private func reelPager(pageHeight: CGFloat, pageWidth: CGFloat) -> some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.posts) { post in
                    ReflectReelPage(
                        post: post,
                        pageHeight: pageHeight,
                        isTogglingLike: viewModel.isTogglingLike(postId: post.id),
                        onToggleLike: {
                            Task { await viewModel.toggleLike(for: post) }
                        },
                        onTapVerse: { key in
                            fetchAndShowVerse(key: key)
                        }
                    )
                    .frame(width: pageWidth, height: pageHeight)
                    .id(post.id)
                    .onAppear {
                        viewModel.loadMoreIfNeeded(currentPost: post)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .scrollIndicators(.hidden)
        .clipped()
        .refreshable {
            await viewModel.loadPosts(refresh: true, force: true)
        }
    }

    private func fetchAndShowVerse(key: String) {
        isLoadingVerse = true
        verseSheetData = nil
        selectedVerseItem = VerseSheetItem(verseKey: key)

        Task {
            guard let content = container?.content else {
                isLoadingVerse = false
                return
            }
            do {
                let response = try await content.getVerseByKey(verseKey: key)
                verseSheetData = response
            } catch {
            }
            isLoadingVerse = false
        }
    }

    private func reelLoadingStack(pageHeight: CGFloat) -> some View {
        TabView {
            ForEach(0..<3, id: \.self) { _ in
                ReflectReelSkeletonPage(pageHeight: pageHeight)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func reelErrorState(
        message: String,
        segment: ReflectPostsSegment,
        retry: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 88, height: 88)
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text(segment == .myPosts ? "Couldn\u{2019}t load your reflections" : "Couldn\u{2019}t load all reflections")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: retry) {
                Text("Try again")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.Theme.deepEmerald)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .alKhatibAccessibility(label: AlKhatibAccessibility.Reflect.tryAgain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func reelEmptyState(segment: ReflectPostsSegment) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 96, height: 96)
                Circle()
                    .fill(.white.opacity(0.04))
                    .frame(width: 72, height: 72)
                Image(systemName: segment == .myPosts ? "person.crop.rectangle.stack" : "sparkles")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Text(segment == .myPosts ? "No reflections yet" : "Nothing here yet")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(
                segment == .myPosts
                    ? "Publish a reflection from Today to see it here."
                    : "Be the first \u{2014} share what this ayah means to you."
            )
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.65))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

            if segment == .myPosts {
                Text("Start Reflecting")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.Theme.deepEmerald)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(.white)
                    .clipShape(Capsule())
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct VerseSheetItem: Identifiable {
    let id: String
    init(verseKey: String) { self.id = verseKey }
}

private struct ReflectFeedTabBar: View {
    @Binding var selection: ReflectPostsSegment
    @Namespace private var tabNamespace

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ReflectPostsSegment.allCases) { segment in
                let isSelected = selection == segment
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selection = segment
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: segment == .feed ? "sparkles" : "person.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(segment.title)
                            .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                    }
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.45))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(.white.opacity(0.15))
                                .matchedGeometryEffect(id: "reflectTab", in: tabNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    AlKhatibAccessibility.Reflect.segmentTab(segment.title, isSelected: isSelected)
                )
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial.opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }
}

private struct ReflectReelPage: View {
    let post: ReflectFeedPost
    let pageHeight: CGFloat
    var isTogglingLike: Bool = false
    var onToggleLike: () -> Void = {}
    var onTapVerse: (String) -> Void = { _ in }

    @State private var heartScale: CGFloat = 1.0
    @State private var heartBounce = false
    @State private var showShareSheet = false
    @State private var ambientPhase: CGFloat = 0

    private var verseKey: String? {
        post.references?.first?.verseKey
    }

    private var formattedDate: String {
        guard let createdAt = post.createdAt else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: createdAt) {
            return date.relativeFormatted
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: createdAt) {
            return date.relativeFormatted
        }
        return createdAt
    }

    var body: some View {
        GeometryReader { proxy in
            let actionBottomPadding = max(proxy.safeAreaInsets.bottom + 72, 96)

            ZStack {
                reelBackground

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: 12)

                    glassmorphicCard
                        .padding(.horizontal, 16)
                        .padding(.trailing, 48)

                    Spacer()
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)

                VStack {
                    Spacer()
                    actionRail
                }
                .padding(.trailing, 12)
                .padding(.bottom, actionBottomPadding)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomTrailing)
            }
        }
        .frame(height: pageHeight)
        .clipped()
        .accessibilityHint(AlKhatibAccessibility.Reflect.scrollPosts)
        .sheet(isPresented: $showShareSheet) {
            if let body = post.body {
                let shareLabel = verseKey.map { VerseKeyFormat.humanLabel(for: $0) } ?? ""
                let shareContent = shareLabel.isEmpty
                    ? body
                    : "\(body)\n\n— \(shareLabel)"
                ShareActivityView(activityItems: [shareContent])
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                ambientPhase = 1
            }
        }
    }

    private var reelBackground: some View {
        ZStack {
            ReflectReelChrome.gradient
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    ReflectReelChrome.ambientTeal.opacity(0.15 + ambientPhase * 0.08),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 350
            )
            .allowsHitTesting(false)

            RadialGradient(
                colors: [
                    ReflectReelChrome.ambientGold.opacity(0.06 + ambientPhase * 0.04),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 280
            )
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color.Token.forestDark.opacity(0.55),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                Spacer()
                LinearGradient(
                    colors: [
                        .clear,
                        Color.Token.forestDeeper.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    private var glassmorphicCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            profileSection
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 14)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.08),
                            Color.Theme.gold.opacity(0.12),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
                .padding(.horizontal, 18)

            postContentSection
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 18)
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            authorRow

            if let key = verseKey {
                Button {
                    onTapVerse(key)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(VerseKeyFormat.humanLabel(for: key))
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Color.Theme.gold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [
                                    Color.Theme.gold.opacity(0.2),
                                    Color.Theme.gold.opacity(0.1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.Theme.gold.opacity(0.3), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var postContentSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                if let body = post.body, body.isEmpty == false {
                    ReflectPostText(text: body, foreground: .white, fontSize: 16)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(post.spokenAccessibilitySummary)
        .accessibilityAddTraits(.isStaticText)
    }

    private var authorRow: some View {
        HStack(alignment: .center, spacing: 12) {
            authorAvatar(size: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(post.author?.displayName ?? "Contributor")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if post.author?.verified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.Theme.gold)
                    }
                }

                if formattedDate.isEmpty == false {
                    Text(formattedDate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var actionRail: some View {
        VStack(spacing: 22) {
            springHeartButton
            reelActionButton(
                icon: "bubble.right.fill",
                label: formatCount(post.commentsCount),
                accessibilityLabel: "Comments, \(post.commentsCount ?? 0)",
                isHighlighted: false,
                action: nil
            )
            reelActionButton(
                icon: "arrowshape.turn.up.right.fill",
                label: "",
                accessibilityLabel: "Share reflection",
                isHighlighted: false,
                action: { showShareSheet = true }
            )
        }
    }

    private var springHeartButton: some View {
        let isLiked = post.isLiked == true

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.1)) {
                heartScale = 1.35
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    heartScale = 1.0
                }
            }
            onToggleLike()
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.6))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(
                                    isLiked
                                        ? LinearGradient(
                                            colors: [
                                                Color(red: 1, green: 0.35, blue: 0.45).opacity(0.4),
                                                Color(red: 1, green: 0.2, blue: 0.4).opacity(0.15)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        : LinearGradient(
                                            colors: [.white.opacity(0.15), .white.opacity(0.08)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                    lineWidth: 0.8
                                )
                        )

                    if isTogglingLike {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(
                                isLiked
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 1, green: 0.35, blue: 0.45),
                                                Color(red: 1, green: 0.2, blue: 0.4)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    : AnyShapeStyle(.white)
                            )
                            .scaleEffect(heartScale)
                    }
                }

                if let count = post.likesCount, count > 0 {
                    Text(formatCount(count))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 52)
        }
        .buttonStyle(.plain)
        .disabled(isTogglingLike)
        .accessibilityLabel(
            AlKhatibAccessibility.Reflect.like(
                isLiked: isLiked,
                count: post.likesCount ?? 0
            )
        )
    }

    private func reelActionButton(
        icon: String,
        label: String,
        accessibilityLabel: String,
        isHighlighted: Bool,
        isLoading: Bool = false,
        action: (() -> Void)? = nil
    ) -> some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.6))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.12), lineWidth: 0.5)
                        )

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }

                if label.isEmpty == false {
                    Text(label)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 52)
        }
        .buttonStyle(.plain)
        .disabled(action == nil || isLoading)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func authorAvatar(size: CGFloat) -> some View {
        if let avatarURL = post.author?.avatarURL {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(
                                LinearGradient(
                                    colors: [
                                        Color.Theme.deepEmerald,
                                        Color.Theme.gold.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                        )
                default:
                    avatarPlaceholder(size: size)
                }
            }
        } else {
            avatarPlaceholder(size: size)
        }
    }

    private func avatarPlaceholder(size: CGFloat) -> some View {
        Circle()
            .fill(.white.opacity(0.12))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(.white.opacity(0.85))
            )
            .overlay(
                Circle().stroke(
                    LinearGradient(
                        colors: [
                            Color.Theme.deepEmerald.opacity(0.5),
                            Color.Theme.gold.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            )
    }

    private func formatCount(_ value: Int?) -> String {
        guard let value, value > 0 else { return "" }
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }
}

private struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct VerseDetailSheet: View {
    let verseKey: String
    let response: SingleVerseResponse?
    let isLoading: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.Token.forestDeeper,
                    Color.Token.forestDark,
                    Color.Token.deepEmerald
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if isLoading && response == nil {
                verseLoadingState
            } else if let verse = response?.verse {
                verseContentView(verse: verse)
            } else if !isLoading {
                verseErrorState
            }
        }
    }

    private var verseLoadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Color.Theme.gold)
                .scaleEffect(1.2)
            Text("Loading verse…")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var verseErrorState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.white.opacity(0.5))
            Text("Could not load verse")
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.8))
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.Theme.deepEmerald)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(.white)
                    .clipShape(Capsule())
            }
        }
    }

    private func verseContentView(verse: RandomAyahPayload) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(VerseKeyFormat.humanLabel(for: verseKey))
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(Color.Theme.gold)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [
                                Color.Theme.gold.opacity(0.2),
                                Color.Theme.gold.opacity(0.08)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.Theme.gold.opacity(0.3), lineWidth: 0.5)
                )

                ornamentalDivider

                if let arabicText = verse.displayText, arabicText.isEmpty == false {
                    VStack(spacing: 8) {
                        Text(arabicText)
                            .font(AlKhatibTypography.quranArabic(size: 28))
                            .multilineTextAlignment(.center)
                            .environment(\.layoutDirection, .rightToLeft)
                            .lineSpacing(12)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                    }
                }

                ornamentalDivider

                if let translations = verse.translations, translations.isEmpty == false {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(translations, id: \.id) { translation in
                            VStack(alignment: .leading, spacing: 6) {
                                if let name = translation.resourceName, name.isEmpty == false {
                                    Text(name)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.Theme.gold.opacity(0.7))
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                }

                                if let text = translation.text {
                                    let cleaned = text.strippingHTMLToPlainText()
                                    Text(cleaned)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(.white.opacity(0.85))
                                        .lineSpacing(4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 32)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
    }

    private var ornamentalDivider: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.Theme.gold.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
            Text("\u{2726}")
                .font(.system(size: 10))
                .foregroundStyle(Color.Theme.gold.opacity(0.5))
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.Theme.gold.opacity(0.2), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
        }
        .padding(.horizontal, 32)
    }
}

private struct ReflectReelSkeletonPage: View {
    let pageHeight: CGFloat

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack {
            ReflectReelChrome.gradient

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        Circle().fill(.white.opacity(0.08)).frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 6) {
                            skeletonBar(width: 130, height: 14)
                            skeletonBar(width: 80, height: 11)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    Rectangle()
                        .fill(.white.opacity(0.04))
                        .frame(height: 0.5)
                        .padding(.horizontal, 18)
                        .padding(.top, 14)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(0..<4, id: \.self) { i in
                            skeletonBar(width: i == 3 ? 200 : nil, height: 15)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 18)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.trailing, 48)

                Spacer()
            }

            VStack {
                Spacer()
                VStack(spacing: 22) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(.white.opacity(0.08)).frame(width: 48, height: 48)
                    }
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 108)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(height: pageHeight)
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }

    private func skeletonBar(width: CGFloat? = nil, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.white.opacity(0.06))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.05), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
            )
            .clipped()
    }
}
