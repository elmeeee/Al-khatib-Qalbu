//
//  VerseAudioBar.swift
//  Al-Khatib
//

import SwiftUI

struct VerseAudioBar: View {
    @ObservedObject var audio: AudioPlayerController

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Theme.gold.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "waveform")
                        .foregroundColor(Color.Theme.gold)
                )

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

            Button { audio.toggle() } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 44)
            }

            Button { audio.stop() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 44)
            }
        }
        .padding(8)
        .background(Capsule().fill(.regularMaterial))
        .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.12), radius: 10, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
