//
//  ReflectReelPostCardView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectReelPostCardView: View {
    let post: ReflectFeedPost
    let verseKey: String?
    let formattedDate: String
    var onTapVerse: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReflectReelProfileHeaderView(
                post: post,
                verseKey: verseKey,
                formattedDate: formattedDate,
                onTapVerse: onTapVerse
            )
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.08),
                            Color.Token.gold.opacity(0.12),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
                .padding(.horizontal, 18)

            ReflectReelPostBodyView(post: post)
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 18)
        }
    }
}
