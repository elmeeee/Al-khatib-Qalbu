//
//  ReflectReelPageView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectReelPageView: View {
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
