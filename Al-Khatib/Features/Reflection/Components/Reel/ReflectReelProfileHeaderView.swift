//
//  ReflectReelProfileHeaderView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectReelProfileHeaderView: View {
    let post: ReflectFeedPost
    let verseKey: String?
    let formattedDate: String
    var onTapVerse: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                ReflectReelAuthorAvatarView(avatarURL: post.author?.avatarURL)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(post.author?.displayName ?? "Contributor")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if post.author?.verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.Token.gold)
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

            if let key = verseKey {
                Button { onTapVerse(key) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(VerseKeyFormat.humanLabel(for: key))
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Color.Token.gold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [
                                    Color.Token.gold.opacity(0.2),
                                    Color.Token.gold.opacity(0.1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.Token.gold.opacity(0.3), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
