//
//  VerseAudioBar.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct VerseAudioBar: View {
    @ObservedObject var audio: AudioPlayerController
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 12) {
            // Waveform icon with pulse animation when playing
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Theme.deepEmerald.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.Theme.deepEmerald)
                        .scaleEffect(isPulsing ? 1.15 : 1.0)
                        .opacity(isPulsing ? 0.7 : 1.0)
                )
                .onChangeWithFallback(of: audio.isPlaying) { playing in
                    withAnimation(
                        playing
                            ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                            : .easeOut(duration: 0.2)
                    ) {
                        isPulsing = playing
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(audio.trackTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(audio.trackSubtitle.isEmpty ? audio.reciterName : audio.trackSubtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            // Play/Pause with emerald gradient background
            Button { audio.toggle() } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.Theme.deepEmerald, Color(hex: "#0F766E")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color.Theme.deepEmerald.opacity(0.25), radius: 4, y: 2)
            }

            Button { audio.stop() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 44)
            }
        }
        .padding(10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(Color.Theme.deepEmerald.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, y: 6)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
