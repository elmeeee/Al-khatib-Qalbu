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

    @State private var showShareSheet = false
    @State private var ambientPhase: CGFloat = 0

    private var verseKey: String? {
        post.references?.first?.verseKey
    }

    private var formattedDate: String {
        ReflectPostDateFormatting.relativeLabel(iso8601: post.createdAt)
    }

    var body: some View {
        GeometryReader { proxy in
            let actionBottomPadding = max(proxy.safeAreaInsets.bottom + 72, 96)

            ZStack {
                ReflectReelBackgroundView(ambientPhase: $ambientPhase)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: 12)

                    ReflectReelPostCardView(
                        post: post,
                        verseKey: verseKey,
                        formattedDate: formattedDate,
                        onTapVerse: onTapVerse
                    )
                    .padding(.horizontal, 16)
                    .padding(.trailing, 48)

                    Spacer()
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)

                VStack {
                    Spacer()
                    ReflectReelActionRailView(
                        post: post,
                        isTogglingLike: isTogglingLike,
                        onToggleLike: onToggleLike,
                        showShareSheet: $showShareSheet
                    )
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
    }
}
