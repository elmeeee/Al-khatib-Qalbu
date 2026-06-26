//
//  ChapterIntroPage.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ChapterIntroPage: View {
    @Environment(\.chapterReaderChromeInsets) private var chromeInsets

    let chapter: QuranChapter
    let isPreparingPlayAll: Bool
    let onPlayAll: () -> Void
    let onTapScreen: () -> Void

    @State private var showTapFeedback = false
    @State private var bounceChevron = false
    @State private var appear = false

    var body: some View {
        ZStack {
            ChapterReaderBackground()

            // Ambient glow
            GeometryReader { geo in
                RadialGradient(
                    colors: [Color.Token.gold.opacity(0.10), Color.clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: geo.size.width * 0.55
                )
                .frame(width: geo.size.width, height: geo.size.width)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.38)
            }

            VStack(spacing: 0) {
                Spacer(minLength: 20)

                // ── Chapter Number Badge ─────────────────────────────
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.Token.gold.opacity(0.25), Color.Token.deepEmerald.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle().stroke(Color.Token.gold.opacity(0.4), lineWidth: 1.5)
                        )
                    Text("\(chapter.id)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color.Token.gold)
                }
                .scaleEffect(appear ? 1 : 0.6)
                .opacity(appear ? 1 : 0)
                .padding(.bottom, 20)

                // ── Bismillah Banner ─────────────────────────────────
                if chapter.id != 9 {
                    Text("\u{FDFD}")
                        .font(.system(size: 28))
                        .foregroundColor(Color.Token.gold.opacity(0.85))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.Token.gold.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .offset(y: appear ? 0 : 12)
                        .opacity(appear ? 1 : 0)
                        .padding(.bottom, 28)
                }

                ornamentDivider.padding(.bottom, 20)

                // ── Arabic Name ──────────────────────────────────────
                if let arabic = chapter.nameArabic, arabic.isEmpty == false {
                    Text(arabic)
                        .font(.system(size: 52, weight: .medium))
                        .foregroundColor(.white)
                        .environment(\.layoutDirection, .rightToLeft)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.Token.gold.opacity(0.2), radius: 8, y: 4)
                        .offset(y: appear ? 0 : 10)
                        .opacity(appear ? 1 : 0)
                        .padding(.bottom, 6)
                }

                // ── Latin Name ───────────────────────────────────────
                Text(chapter.displayComplexName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(appear ? 1 : 0)
                    .padding(.bottom, 4)

                // ── Translated Name ──────────────────────────────────
                if chapter.displayTranslatedName.isEmpty == false {
                    Text(chapter.displayTranslatedName)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(Color.Token.gold.opacity(0.9))
                        .italic()
                        .opacity(appear ? 1 : 0)
                        .padding(.bottom, 20)
                }

                // ── Meta Chips ───────────────────────────────────────
                HStack(spacing: 10) {
                    ChapterRevelationBadge(chapter: chapter)
                    if let countLabel = chapter.versesCountLabel {
                        Text(countLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            )
                    }
                }
                .opacity(appear ? 1 : 0)
                .padding(.bottom, 24)

                ornamentDivider

                Text(AppLanguageManager.shared.localize("tap_to_begin"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 20)
                    .opacity(appear ? 1 : 0)

                Spacer()

                // ── Swipe Up Prompt ──────────────────────────────────
                VStack(spacing: 6) {
                    Image(systemName: "chevron.compact.up")
                        .font(.system(size: 22, weight: .semibold))
                        .offset(y: bounceChevron ? -5 : 5)
                    Text(AppLanguageManager.shared.localize("swipe_up_intro"))
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                }
                .foregroundColor(.white.opacity(0.35))
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        bounceChevron = true
                    }
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 28)
            .padding(.top, chromeInsets.top)
            .padding(.bottom, chromeInsets.bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .onTapGesture {
                onTapScreen()
                showTapFeedback = true
                Task {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    showTapFeedback = false
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.55)) { appear = true }
            }

            // Tap feedback
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.Token.deepEmerald.opacity(0.6), Color.Token.gold.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: showTapFeedback ? 0 : 8)
                    .opacity(showTapFeedback ? 1.0 : 0.3)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.white.opacity(showTapFeedback ? 0.95 : 0.3))
                    .scaleEffect(showTapFeedback ? 1.05 : 1.0)
                    .animation(.easeOut(duration: 0.2), value: showTapFeedback)
            }
            .allowsHitTesting(false)
        }
        .clipped()
    }

    private var ornamentDivider: some View {
        HStack(spacing: 10) {
            ornamentLine
            Image(systemName: "sparkle")
                .font(.system(size: 9))
                .foregroundColor(Color.Token.gold.opacity(0.6))
            ornamentLine
        }
        .frame(width: 180)
    }

    private var ornamentLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.Token.gold.opacity(0.05),
                        Color.Token.gold.opacity(0.4),
                        Color.Token.gold.opacity(0.05)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}
