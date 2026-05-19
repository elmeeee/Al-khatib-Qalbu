//
//  ChapterAyahCard.swift
//  Al-Khatib
//

import SwiftUI

struct ChapterAyahCard: View {
    let verse: RandomAyahPayload
    let ayahNumber: Int?
    let isPlaying: Bool
    let onPlay: () -> Void
    let onTafsir: () -> Void

    private var hasAudio: Bool {
        verse.audio?.url?.isEmpty == false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                if let ayahNumber {
                    Text("\(ayahNumber)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(isPlaying ? Color.Theme.pureWhite : Color.Theme.deepEmerald)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(isPlaying ? Color.Theme.gold : Color.Theme.deepEmerald.opacity(0.1))
                        )
                }
                Spacer()
                if isPlaying {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.caption.weight(.semibold))
                        Text("Playing")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(Color.Theme.gold)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            AyahArabicWebBlock(payload: verse)
                .padding(.horizontal, 10)
                .padding(.top, 4)
                .padding(.bottom, 10)

            if let translation = verse.translations?.first,
               let text = translation.text,
               text.isEmpty == false {
                Text(text)
                    .font(.system(size: 16))
                    .lineSpacing(4)
                    .foregroundStyle(.primary.opacity(0.92))
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.Theme.deepEmerald.opacity(0.15), Color.Theme.gold.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(spacing: 0) {
                if hasAudio {
                    cardAction(icon: "play.circle.fill", label: "Play", isActive: isPlaying, action: onPlay)
                }
                cardAction(icon: "book.closed.fill", label: "Tafsir", isActive: false, action: onTafsir)
            }
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.Theme.pureWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isPlaying ? Color.Theme.gold : Color.Theme.softGrey.opacity(0.7),
                    lineWidth: isPlaying ? 2 : 1
                )
        )
        .shadow(
            color: isPlaying ? Color.Theme.gold.opacity(0.2) : Color.black.opacity(0.05),
            radius: isPlaying ? 12 : 6,
            y: 3
        )
    }

    private func cardAction(
        icon: String,
        label: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isActive ? Color.Theme.gold : Color.Theme.deepEmerald)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
