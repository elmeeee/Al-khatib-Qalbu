//
//  ReflectReelAuthorAvatarView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectReelAuthorAvatarView: View {
    let avatarURL: URL?
    var size: CGFloat = 44

    var body: some View {
        if let avatarURL {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(avatarBorder)
                default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(.white.opacity(0.12))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(.white.opacity(0.85))
            )
            .overlay(avatarBorder)
    }

    private var avatarBorder: some View {
        Circle().stroke(
            LinearGradient(
                colors: [
                    Color.Token.deepEmerald,
                    Color.Token.gold.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 2.5
        )
    }
}
