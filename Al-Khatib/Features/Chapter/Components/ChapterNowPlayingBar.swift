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
                    .foregroundStyle(Color.Token.slate800)
                    .lineLimit(1)

                if audio.reciterName.isEmpty == false {
                    Text(audio.reciterName)
                        .font(.caption)
                        .foregroundStyle(Color.Token.slate500)
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
                                            Color.Token.deepEmerald,
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
                        .foregroundStyle(Color.Token.slate500)
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
                .fill(Color.Token.pureWhite)
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: 5)
                .overlay {
                    RoundedRectangle(cornerRadius: TabBarLayout.chromeCornerRadius, style: .continuous)
                        .stroke(Color.Token.softGrey, lineWidth: 0.5)
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
                            Color.Token.gold.opacity(0.45),
                            Color.Token.gold.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.Token.gold.opacity(0.25), lineWidth: 0.5)
                )
            Image(systemName: audio.isPlaying ? "waveform" : "play.fill")
                .font(.system(size: audio.isPlaying ? 14 : 12, weight: .semibold))
                .foregroundStyle(Color.Token.gold)
                .symbolEffect(.variableColor.iterative, isActive: audio.isPlaying)
        }
        .frame(width: 40, height: 40)
    }
}
