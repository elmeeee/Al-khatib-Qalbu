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
            Color(hex: "#0B3D34"),
            Color.Theme.deepEmerald,
            Color(hex: "#051F1A")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let fillColor = Color(hex: "#051F1A")
}

struct ReflectReelFeedView: View {
    @Bindable var viewModel: ReflectionViewModel

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
                                .background(.black.opacity(0.45))
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
    }

    private func reelPager(pageHeight: CGFloat, pageWidth: CGFloat) -> some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.posts) { post in
                    ReflectReelPage(post: post, pageHeight: pageHeight)
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
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white.opacity(0.7))

            Text(segment == .myPosts ? "Couldn't load your reflections" : "Couldn't load the feed")
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func reelEmptyState(segment: ReflectPostsSegment) -> some View {
        VStack(spacing: 16) {
            Image(systemName: segment == .myPosts ? "person.crop.rectangle.stack" : "sparkles")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.5))

            Text(segment == .myPosts ? "No reflections yet" : "Nothing here yet")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(
                segment == .myPosts
                    ? "Publish a reflection from Today to see it here."
                    : "Be the first — share what this ayah means to you."
            )
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.65))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ReflectFeedTabBar: View {
    @Binding var selection: ReflectPostsSegment
    @Namespace private var tabNamespace

    var body: some View {
        HStack(spacing: 32) {
            ForEach(ReflectPostsSegment.allCases) { segment in
                let isSelected = selection == segment
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selection = segment
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(segment.title)
                            .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.45))

                        if isSelected {
                            Capsule()
                                .fill(Color.white)
                                .frame(width: 24, height: 2.5)
                                .matchedGeometryEffect(id: "reflectTab", in: tabNamespace)
                        } else {
                            Capsule()
                                .fill(.clear)
                                .frame(width: 24, height: 2.5)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .background(.clear)
    }
}

private struct ReflectReelPage: View {
    let post: ReflectFeedPost
    let pageHeight: CGFloat

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

                LinearGradient(
                    colors: [
                        Color(hex: "#0B3D34").opacity(0.5),
                        .clear,
                        .clear,
                        Color(hex: "#051F1A").opacity(0.35)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 0) {
                    profileSection
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    postContentSection
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.bottom, 12)
                }
                .padding(.trailing, 60)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)

                // Floating actions — lower right (white)
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
    }

    // MARK: Red zone — profile at top

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            authorRow

            if let key = verseKey {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(VerseKeyFormat.humanLabel(for: key))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.Theme.gold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.white.opacity(0.14))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: Blue zone — post body + tags only

    private var postContentSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                if let body = post.body, body.isEmpty == false {
                    ReflectPostText(text: body, foreground: .white, fontSize: 14)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let tags = post.tags, tags.isEmpty == false {
                    FlowLayoutTags(tags: tags)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
        }
    }

    private var authorRow: some View {
        HStack(alignment: .center, spacing: 12) {
            authorAvatar(size: 48)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(post.author?.displayName ?? "Contributor")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if post.author?.verified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.Theme.gold)
                    }
                }

                if formattedDate.isEmpty == false {
                    Text(formattedDate)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var actionRail: some View {
        VStack(spacing: 22) {
            reelActionButton(
                icon: post.isLiked == true ? "heart.fill" : "heart",
                label: formatCount(post.likesCount),
                isHighlighted: post.isLiked == true
            )
            reelActionButton(
                icon: "bubble.right.fill",
                label: formatCount(post.commentsCount),
                isHighlighted: false
            )
            reelActionButton(
                icon: "arrowshape.turn.up.right.fill",
                label: "",
                isHighlighted: false
            )
        }
    }

    private var reelBackground: some View {
        ReflectReelChrome.gradient
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func reelActionButton(icon: String, label: String, isHighlighted: Bool) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(isHighlighted ? Color(red: 1, green: 0.35, blue: 0.45) : .white)
                .shadow(color: .black.opacity(0.45), radius: 6, y: 2)

            if label.isEmpty == false {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 52)
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
                        .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 2))
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
            .fill(.white.opacity(0.18))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(.white.opacity(0.85))
            )
            .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 2))
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

// MARK: - Tags

private struct FlowLayoutTags: View {
    let tags: [ReflectFeedTag]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunkedTagNames(), id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { name in
                        Text("#\(name)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.88))
                    }
                }
            }
        }
    }

    private func chunkedTagNames() -> [[String]] {
        let names = tags.compactMap(\.name).filter { $0.isEmpty == false }
        guard names.isEmpty == false else { return [] }
        var rows: [[String]] = []
        var current: [String] = []
        for name in names {
            current.append(name)
            if current.count >= 3 {
                rows.append(current)
                current = []
            }
        }
        if current.isEmpty == false {
            rows.append(current)
        }
        return rows
    }
}

private struct ReflectReelSkeletonPage: View {
    let pageHeight: CGFloat

    var body: some View {
        ZStack {
            ReflectReelChrome.gradient

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Circle().fill(.white.opacity(0.12)).frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.12)).frame(width: 130, height: 14)
                        RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.08)).frame(width: 80, height: 11)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.1))
                            .frame(width: i == 3 ? 200 : nil, height: 15)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .padding(.trailing, 60)

            VStack {
                Spacer()
                VStack(spacing: 22) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(.white.opacity(0.12)).frame(width: 36, height: 36)
                    }
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 108)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(height: pageHeight)
        .clipped()
    }
}
