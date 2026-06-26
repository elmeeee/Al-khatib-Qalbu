//
//  QuranPlaybackLiveActivity.swift
//  AlKhatibLiveActivity
//
//  Created by Elmee on 26/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity widget for Quran audio playback.
/// Renders on the Dynamic Island (compact, expanded, minimal) and Lock Screen.
struct QuranPlaybackLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuranPlaybackAttributes.self) { context in
            // Lock Screen / StandBy banner
            lockScreenBanner(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded presentation
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: context.state.isPlaying ? "waveform" : "pause.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.teal)
                            .symbolEffect(.variableColor.iterative, isActive: context.state.isPlaying)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.surahName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(verseProgressLabel(context: context))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.reciterName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.15))
                                .frame(height: 4)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.teal, .green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geo.size.width * context.state.progress, 4), height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                }
            } compactLeading: {
                // Compact leading — icon
                Image(systemName: context.state.isPlaying ? "waveform" : "book.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.teal)
                    .symbolEffect(.variableColor.iterative, isActive: context.state.isPlaying)
            } compactTrailing: {
                // Compact trailing — verse label
                Text("Ayah \(context.state.verseLabel)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            } minimal: {
                // Minimal — just an icon
                Image(systemName: context.state.isPlaying ? "waveform" : "book.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.teal)
                    .symbolEffect(.variableColor.iterative, isActive: context.state.isPlaying)
            }
        }
    }

    // MARK: – Lock Screen Banner

    @ViewBuilder
    private func lockScreenBanner(context: ActivityViewContext<QuranPlaybackAttributes>) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Quran icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.teal.opacity(0.3), Color.green.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: context.state.isPlaying ? "waveform" : "book.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.teal)
                        .symbolEffect(.variableColor.iterative, isActive: context.state.isPlaying)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.surahName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(verseProgressLabel(context: context))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))

                        Text("•")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))

                        Text(context.attributes.reciterName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Play status indicator
                Image(systemName: context.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.teal)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: 3)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.teal, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * context.state.progress, 3), height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(16)
        .background(Color.black.opacity(0.85))
    }

    // MARK: – Helpers

    private func verseProgressLabel(context: ActivityViewContext<QuranPlaybackAttributes>) -> String {
        if context.state.totalVerses > 0 {
            return "Ayah \(context.state.currentVerse)/\(context.state.totalVerses)"
        }
        return "Ayah \(context.state.verseLabel)"
    }
}
