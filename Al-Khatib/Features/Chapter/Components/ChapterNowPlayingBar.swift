//
//  ChapterNowPlayingBar.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ChapterNowPlayingBar: View {
    @ObservedObject var audio: AudioPlayerController

    var body: some View {
        HStack(spacing: 12) {
            artwork

            VStack(alignment: .leading, spacing: 3) {
                Text(trackLine)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if audio.reciterName.isEmpty == false {
                    Text(audio.reciterName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Button { audio.toggle() } label: {
                    Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.Theme.deepEmerald,
                                            Color.Token.tealDark
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(audio.isPlaying ? "Pause recitation" : "Play recitation")
                .accessibilityHint(trackLine)

                Button { audio.stop() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 32, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop audio")
            }
        }
        .accessibilityElement(children: .contain)
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: TabBarLayout.chromeCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.35))
                .background {
                    RoundedRectangle(cornerRadius: TabBarLayout.chromeCornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: TabBarLayout.chromeCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                }
        }
    }

    private var trackLine: String {
        let surah = audio.trackTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let ayah = audio.trackSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if surah.isEmpty, ayah.isEmpty { return "" }
        if ayah.isEmpty { return surah }
        if surah.isEmpty { return ayah }
        return "\(surah)\u{30FB}\(ayah)"
    }

    private var artwork: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.Theme.gold.opacity(0.45),
                            Color.Theme.gold.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.Theme.gold.opacity(0.25), lineWidth: 0.5)
                )
            Image(systemName: audio.isPlaying ? "waveform" : "play.fill")
                .font(.system(size: audio.isPlaying ? 14 : 12, weight: .semibold))
                .foregroundStyle(Color.Theme.gold)
                .symbolEffect(.variableColor.iterative, isActive: audio.isPlaying)
        }
        .frame(width: 40, height: 40)
    }
}
