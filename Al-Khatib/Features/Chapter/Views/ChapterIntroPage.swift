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

            VStack(spacing: 0) {
                Spacer(minLength: 20)

                // ── Chapter Number Badge ─────────────────────────────
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.Token.gold.opacity(0.15), Color.Token.forestDeeper.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.Token.goldBright, Color.Token.gold.opacity(0.3), Color.Token.goldBright],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.Token.gold.opacity(0.2), radius: 8, x: 0, y: 4)
                    Text("\(chapter.id)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color.Token.goldBright)
                }
                .scaleEffect(appear ? 1 : 0.6)
                .opacity(appear ? 1 : 0)
                .padding(.bottom, 24)

                // ── Bismillah Banner ─────────────────────────────────
                if chapter.id != 9 {
                    Text("\u{FDFD}")
                        .font(.system(size: 32))
                        .foregroundColor(Color.Token.goldBright)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.Token.gold.opacity(0.35), Color.Token.gold.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.2
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                        )
                        .offset(y: appear ? 0 : 12)
                        .opacity(appear ? 1 : 0)
                        .padding(.bottom, 28)
                }

                ornamentDivider.padding(.bottom, 20)

                // ── Arabic Name ──────────────────────────────────────
                if let arabic = chapter.nameArabic, arabic.isEmpty == false {
                    Text(arabic)
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                        .environment(\.layoutDirection, .rightToLeft)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.Token.gold.opacity(0.35), radius: 12, y: 6)
                        .offset(y: appear ? 0 : 10)
                        .opacity(appear ? 1 : 0)
                        .padding(.bottom, 8)
                }

                // ── Latin Name ───────────────────────────────────────
                Text(chapter.displayComplexName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                    .opacity(appear ? 1 : 0)
                    .padding(.bottom, 4)

                // ── Translated Name ──────────────────────────────────
                if chapter.displayTranslatedName.isEmpty == false {
                    Text(chapter.displayTranslatedName)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(Color.Token.goldBright.opacity(0.95))
                        .italic()
                        .opacity(appear ? 1 : 0)
                        .padding(.bottom, 24)
                }

                // ── Meta Chips ───────────────────────────────────────
                HStack(spacing: 12) {
                    ChapterRevelationBadge(chapter: chapter, isOnDark: true)
                    if let countLabel = chapter.versesCountLabel {
                        Text(countLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            )
                    }
                }
                .opacity(appear ? 1 : 0)
                .padding(.bottom, 24)

                ornamentDivider

                Text(AppLanguageManager.shared.localize("tap_to_begin"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.top, 24)
                    .opacity(appear ? 1 : 0)

                Spacer()

                // ── Swipe Up Prompt ──────────────────────────────────
                VStack(spacing: 8) {
                    Image(systemName: "chevron.compact.up")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.Token.goldBright.opacity(0.8))
                        .offset(y: bounceChevron ? -6 : 4)
                    Text(AppLanguageManager.shared.localize("swipe_up_intro"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.4)
                }
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
            if showTapFeedback {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 80, height: 80)
                    .blur(radius: 4)
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
            }
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
