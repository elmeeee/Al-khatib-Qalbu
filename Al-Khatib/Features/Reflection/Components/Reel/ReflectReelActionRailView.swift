//
//  ReflectReelActionRailView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectReelActionRailView: View {
    let post: ReflectFeedPost
    var isTogglingLike: Bool = false
    var onToggleLike: () -> Void = {}
    @Binding var showShareSheet: Bool

    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 22) {
            springHeartButton
            reelActionButton(
                icon: "bubble.right.fill",
                label: ReflectSocialCountFormatting.label(for: post.commentsCount),
                accessibilityLabel: "Comments, \(post.commentsCount ?? 0)",
                action: nil
            )
            reelActionButton(
                icon: "arrowshape.turn.up.right.fill",
                label: "",
                accessibilityLabel: "Share reflection",
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

                let likeLabel = ReflectSocialCountFormatting.label(for: post.likesCount)
                if likeLabel.isEmpty == false {
                    Text(likeLabel)
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
}
