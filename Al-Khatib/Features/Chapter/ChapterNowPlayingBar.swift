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
        HStack(spacing: 10) {
            Image(systemName: audio.isPlaying ? "waveform" : "pause.fill")
                .font(.caption.weight(.bold))
                .foregroundColor(Color.Theme.gold)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text("Playing")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white.opacity(0.9))
                Text(audio.trackSubtitle.isEmpty ? audio.reciterName : audio.trackSubtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.78))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button { audio.toggle() } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
            }

            Button { audio.stop() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.65))
                    .frame(width: 28, height: 32)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: TabBarLayout.chromeCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.14))
                .overlay {
                    RoundedRectangle(cornerRadius: TabBarLayout.chromeCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                }
        }
    }
}
