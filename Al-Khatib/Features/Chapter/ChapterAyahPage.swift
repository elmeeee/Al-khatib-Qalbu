//
//  ChapterAyahPage.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI
internal import UIKit

struct ChapterAyahPage: View {
    @Environment(\.chapterReaderChromeInsets) private var chromeInsets

    let verse: RandomAyahPayload
    let showTranslation: Bool
    let fontScale: Double
    let isPlaying: Bool
    let onTapScreen: () -> Void

    @State private var showTapFeedback = false
    @State private var arabicMeasuredHeight: CGFloat = 120
    @State private var layoutScale: Double = 1.0

    private let contentSpacing: CGFloat = 14
    private let minimumLayoutScale: Double = 0.68

    private var hasAudio: Bool {
        verse.audio?.url?.isEmpty == false
    }

    private var effectiveFontScale: Double {
        fontScale * layoutScale
    }

    private var translationText: String? {
        guard showTranslation,
              let translation = verse.translations?.first,
              let text = translation.text,
              text.isEmpty == false else {
            return nil
        }
        return text
    }

    private var translationFontSize: CGFloat {
        CGFloat(17 * effectiveFontScale)
    }

    var body: some View {
        ZStack {
            ChapterReaderBackground()

            GeometryReader { geometry in
                let availableHeight = geometry.size.height

                VStack(alignment: .center, spacing: 0) {
                    VStack(spacing: contentSpacing) {
                        AyahArabicWebBlock(
                            payload: verse,
                            style: .verseCardOnDark,
                            fontScale: effectiveFontScale,
                            measuredHeight: $arabicMeasuredHeight
                        )
                        .padding(.horizontal, 8)

                        if let translationText {
                            Text(justifiedTranslation(translationText))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .minimumScaleFactor(0.82)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 20)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, chromeInsets.top)
                .padding(.bottom, chromeInsets.bottom)
                .frame(width: geometry.size.width, height: availableHeight, alignment: .top)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard hasAudio else { return }
                    onTapScreen()
                    pulseTapFeedback()
                }
                .onAppear {
                    layoutScale = 1.0
                    recalculateLayoutScale(
                        availableHeight: availableHeight,
                        contentWidth: geometry.size.width
                    )
                }
                .onChange(of: availableHeight) { _, height in
                    recalculateLayoutScale(
                        availableHeight: height,
                        contentWidth: geometry.size.width
                    )
                }
                .onChange(of: arabicMeasuredHeight) { _, _ in
                    recalculateLayoutScale(
                        availableHeight: availableHeight,
                        contentWidth: geometry.size.width
                    )
                }
                .onChange(of: fontScale) { _, _ in
                    layoutScale = 1.0
                    recalculateLayoutScale(
                        availableHeight: availableHeight,
                        contentWidth: geometry.size.width
                    )
                }
                .onChange(of: showTranslation) { _, _ in
                    recalculateLayoutScale(
                        availableHeight: availableHeight,
                        contentWidth: geometry.size.width
                    )
                }
                .onChange(of: chromeInsets) { _, _ in
                    recalculateLayoutScale(
                        availableHeight: availableHeight,
                        contentWidth: geometry.size.width
                    )
                }
            }

            if hasAudio {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(showTapFeedback ? 0.85 : 0))
                    .scaleEffect(showTapFeedback ? 1.0 : 0.85)
                    .animation(.easeOut(duration: 0.2), value: showTapFeedback)
                    .allowsHitTesting(false)
            }
        }
        .clipped()
    }

    private func recalculateLayoutScale(availableHeight: CGFloat, contentWidth: CGFloat) {
        guard availableHeight > 0 else { return }

        let translationHeight = estimatedTranslationHeight(width: contentWidth - 72)
        let budget = availableHeight - translationHeight - contentSpacing - chromeInsets.top - chromeInsets.bottom
        guard budget > 0, arabicMeasuredHeight > 0 else { return }

        if arabicMeasuredHeight <= budget {
            layoutScale = 1.0
            return
        }

        let target = budget / arabicMeasuredHeight
        layoutScale = max(minimumLayoutScale, min(1.0, target))
    }

    private func justifiedTranslation(_ text: String) -> AttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .justified
        paragraph.lineSpacing = 5
        let ns = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: translationFontSize),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9),
                .paragraphStyle: paragraph
            ]
        )
        return AttributedString(ns)
    }

    private func estimatedTranslationHeight(width: CGFloat) -> CGFloat {
        guard let text = translationText else { return 0 }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .justified
        paragraph.lineSpacing = 5
        let font = UIFont.systemFont(ofSize: translationFontSize)
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font, .paragraphStyle: paragraph],
            context: nil
        )
        return ceil(rect.height)
    }

    private func pulseTapFeedback() {
        showTapFeedback = true
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            showTapFeedback = false
        }
    }
}
