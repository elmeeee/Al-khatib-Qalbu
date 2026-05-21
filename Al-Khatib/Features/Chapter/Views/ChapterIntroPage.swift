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

    var body: some View {
        ZStack {
            ChapterReaderBackground()

            GeometryReader { geo in
                RadialGradient(
                    colors: [
                        Color.Token.gold.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 40,
                    endRadius: geo.size.width * 0.5
                )
                .frame(width: geo.size.width, height: geo.size.width)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
            }

            VStack(spacing: 0) {
                Spacer(minLength: 20)

                Text("\u{FDFD}")
                    .font(.system(size: 32))
                    .foregroundColor(Color.Token.gold.opacity(0.75))
                    .padding(.bottom, 24)

                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ornamentLine
                        Text("\u{2726}")
                            .font(.system(size: 10))
                            .foregroundColor(Color.Token.gold.opacity(0.6))
                        ornamentLine
                    }
                    .frame(width: 160)

                    if let arabic = chapter.nameArabic, arabic.isEmpty == false {
                        Text(arabic)
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.white)
                            .environment(\.layoutDirection, .rightToLeft)
                            .multilineTextAlignment(.center)
                    }

                    Text(chapter.displayComplexName)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    if chapter.displayTranslatedName.isEmpty == false {
                        Text(chapter.displayTranslatedName)
                            .font(.title3.weight(.medium))
                            .foregroundColor(Color.Token.gold.opacity(0.95))
                    }

                    ChapterRevelationBadge(chapter: chapter)
                        .padding(.top, 4)

                    HStack(spacing: 12) {
                        ornamentLine
                        Text("\u{25C6}")
                            .font(.system(size: 6))
                            .foregroundColor(Color.Token.gold.opacity(0.6))
                        ornamentLine
                    }
                    .frame(width: 160)
                }

                if let countLabel = chapter.versesCountLabel {
                    Text(countLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.65))
                        .padding(.top, 12)
                }

                Text("Tap to begin recitation")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.top, 12)

                Spacer()

                VStack(spacing: 6) {
                    Image(systemName: "chevron.up")
                        .font(.title2.weight(.semibold))
                        .offset(y: bounceChevron ? -4 : 4)
                    Text("Swipe up")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(.white.opacity(0.4))
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        bounceChevron = true
                    }
                }

                Spacer(minLength: 0)
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

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.Token.deepEmerald.opacity(0.6),
                                Color.Token.gold.opacity(0.4)
                            ],
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

    private var ornamentLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.Token.gold.opacity(0.1), Color.Token.gold.opacity(0.35), Color.Token.gold.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}
