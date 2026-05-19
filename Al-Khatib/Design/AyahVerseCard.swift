//
//  AyahVerseCard.swift
//  Al-Khatib
//

import SwiftUI

/// Verse card styled like Today tab `ayahCard` (Arabic, translation, optional actions).
struct AyahVerseCard: View {
    let verse: RandomAyahPayload
    var showsVerseLabel = true
    var onAudio: (() -> Void)?

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

            Rectangle()
                .fill(Color.Theme.deepEmerald)
                .frame(height: 4)

            if let onAudio, verse.audio?.url != nil {
                Button(action: onAudio) {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                        Text("Audio")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color.Theme.deepEmerald)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
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
}
