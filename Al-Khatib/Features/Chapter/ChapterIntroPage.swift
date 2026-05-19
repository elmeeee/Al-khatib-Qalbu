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

    var body: some View {
        ZStack {
            ChapterReaderBackground()

            GeometryReader { geo in
                Circle()
                    .fill(Color.Theme.gold.opacity(0.12))
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: geo.size.width * 0.2, y: -geo.size.height * 0.1)
            }

            VStack(spacing: 20) {
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
                        .foregroundColor(Color.Theme.gold.opacity(0.95))
                }

                if let countLabel = chapter.versesCountLabel {
                    Text(countLabel)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                }

                Text("Tap to play · Swipe up")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 6) {
                    Image(systemName: "chevron.up")
                        .font(.title2.weight(.semibold))
                    Text("Swipe up")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(.white.opacity(0.5))

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

            Image(systemName: "play.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.white.opacity(showTapFeedback ? 0.9 : 0.35))
                .allowsHitTesting(false)
        }
        .clipped()
    }
}
