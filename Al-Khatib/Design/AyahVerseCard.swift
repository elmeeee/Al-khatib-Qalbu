//
//  AyahVerseCard.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct AyahVerseCard: View {
    let verse: RandomAyahPayload
    var showsVerseLabel = true
    var onAudio: (() -> Void)?
    var onTafsir: (() -> Void)?

    private var hasActions: Bool {
        (onAudio != nil && verse.audio?.url != nil) || onTafsir != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                if showsVerseLabel, let key = verse.verseKey {
                    HStack {
                        Text(ShareVerseCard.humanLabel(for: key))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.Theme.deepEmerald)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }

                AyahArabicWebBlock(payload: verse)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, showsVerseLabel ? 8 : 14)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)

                if let translation = verse.translations?.first,
                   let text = translation.text,
                   text.isEmpty == false {
                    Text(text)
                        .font(.system(size: 16))
                        .lineSpacing(3)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                }
            }
            .background(Color.Theme.pureWhite)

            if hasActions {
                Rectangle()
                    .fill(Color.Theme.deepEmerald)
                    .frame(height: 4)

                HStack(spacing: 0) {
                    if let onAudio, verse.audio?.url != nil {
                        actionButton(icon: "speaker.wave.2.fill", text: "Audio", action: onAudio)
                    }
                    if let onTafsir {
                        actionButton(icon: "book.closed.fill", text: "Tafsir", action: onTafsir)
                    }
                }
                .padding(.vertical, 14)
            }
        }
        .transaction { txn in txn.animation = nil }
        .background(Color.Theme.pureWhite.opacity(0.96))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.Theme.softGrey, lineWidth: 1)
        )
    }

    private func actionButton(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(text)
                    .font(.caption)
            }
            .foregroundColor(Color.Theme.deepEmerald)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
