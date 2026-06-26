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
    let showTransliteration: Bool
    let isMemorizationMode: Bool
    let fontScale: Double
    let isPlaying: Bool
    let onTapScreen: () -> Void

    @State private var showTapFeedback = false
    @State private var arabicMeasuredHeight: CGFloat = 120
    @State private var layoutScale: Double = 1.0
    @State private var isRevealed = false

    private let contentSpacing: CGFloat = 16
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

    // Verse number display
    private var verseDisplayNumber: String {
        if let num = verse.resolvedVerseNumber {
            return "\(num)"
        }
        return ""
    }

    var body: some View {
        ZStack {
            ChapterReaderBackground()

            GeometryReader { geometry in
                let availableHeight = geometry.size.height

                VStack(alignment: .center, spacing: 0) {
                    VStack(spacing: contentSpacing) {

                        // ── Memorization Eye ─────────────────────────
                        if isMemorizationMode {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isRevealed.toggle()
                                }
                            } label: {
                                Image(systemName: isRevealed ? "eye.fill" : "eye.slash.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color.Token.goldBright)
                                    .padding(6)
                                    .background(Circle().fill(Color.Token.gold.opacity(0.12)))
                                    .overlay(Circle().stroke(Color.Token.gold.opacity(0.25), lineWidth: 1))
                            }
                            .padding(.top, 4)
                        }

                        // ── Arabic WebBlock ───────────────────────────
                        AyahArabicWebBlock(
                            payload: verse,
                            style: .verseCardOnDark,
                            fontScale: effectiveFontScale,
                            measuredHeight: $arabicMeasuredHeight,
                            includeTranslationInAccessibility: showTranslation
                        )
                        .padding(.horizontal, 8)
                        .blur(radius: (isMemorizationMode && !isRevealed) ? 20 : 0)
                        .overlay {
                            if isMemorizationMode && !isRevealed {
                                HStack(spacing: 4) {
                                    Image(systemName: "eye.slash.fill")
                                        .font(.system(size: 11))
                                    Text(AppLanguageManager.shared.currentLanguage == .english ? "Tap to reveal" : "Ketuk untuk melihat")
                                        .font(.caption2.weight(.bold))
                                }
                                .foregroundColor(Color.Token.goldBright.opacity(0.85))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.black.opacity(0.35)))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isMemorizationMode {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isRevealed.toggle()
                                }
                            }
                        }

                        // ── Transliteration ───────────────────────────
                        if showTransliteration, let latinText = verse.transliteration, latinText.isEmpty == false {
                            Text(latinText)
                                .font(.system(size: CGFloat(15 * effectiveFontScale), weight: .medium, design: .serif))
                                .foregroundColor(Color.Token.goldBright.opacity(0.95))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.04))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [Color.Token.gold.opacity(0.25), Color.Token.gold.opacity(0.05)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                                .blur(radius: (isMemorizationMode && !isRevealed) ? 12 : 0)
                                .overlay {
                                    if isMemorizationMode && !isRevealed {
                                        HStack(spacing: 4) {
                                            Image(systemName: "eye.slash.fill")
                                                .font(.system(size: 11))
                                            Text(AppLanguageManager.shared.currentLanguage == .english ? "Tap to reveal" : "Ketuk untuk melihat")
                                                .font(.caption2.weight(.bold))
                                        }
                                        .foregroundColor(Color.Token.goldBright.opacity(0.85))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(Color.black.opacity(0.35)))
                                    }
                                }
                                .onTapGesture {
                                    if isMemorizationMode {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            isRevealed.toggle()
                                        }
                                    }
                                }
                        }

                        // ── Translation ───────────────────────────────
                        if let translationText {
                            VStack(alignment: .leading, spacing: 0) {
                                // Accent bar
                                HStack(spacing: 0) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.Token.teal, Color.Token.teal.opacity(0.3)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 3)
                                    Text(justifiedTranslation(translationText))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .minimumScaleFactor(0.82)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.05))
                                )
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, chromeInsets.top + 8)
                .padding(.bottom, chromeInsets.bottom)
                .frame(width: geometry.size.width, height: availableHeight, alignment: .top)
                .contentShape(Rectangle())
                .accessibilityAddTraits(hasAudio ? .isButton : [])
                .accessibilityLabel(
                    hasAudio
                        ? (isPlaying ? "Pause ayah recitation" : "Play ayah recitation")
                        : verse.spokenAccessibilitySummary(includeTranslation: showTranslation)
                )
                .accessibilityHint(
                    hasAudio
                        ? "Double tap to play or pause. Arabic with tajweed is shown on screen."
                        : ""
                )
                .onTapGesture {
                    if isMemorizationMode && !isRevealed {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isRevealed = true
                        }
                    } else {
                        guard hasAudio else { return }
                        onTapScreen()
                        pulseTapFeedback()
                    }
                }
                .onAppear {
                    isRevealed = false
                    layoutScale = 1.0
                    recalculateLayoutScale(availableHeight: availableHeight, contentWidth: geometry.size.width)
                }
                .onChange(of: availableHeight) { _, height in
                    recalculateLayoutScale(availableHeight: height, contentWidth: geometry.size.width)
                }
                .onChange(of: arabicMeasuredHeight) { _, _ in
                    recalculateLayoutScale(availableHeight: availableHeight, contentWidth: geometry.size.width)
                }
                .onChange(of: fontScale) { _, _ in
                    layoutScale = 1.0
                    recalculateLayoutScale(availableHeight: availableHeight, contentWidth: geometry.size.width)
                }
                .onChange(of: showTranslation) { _, _ in
                    recalculateLayoutScale(availableHeight: availableHeight, contentWidth: geometry.size.width)
                }
                .onChange(of: chromeInsets) { _, _ in
                    recalculateLayoutScale(availableHeight: availableHeight, contentWidth: geometry.size.width)
                }
            }

            // Tap feedback overlay
            if hasAudio {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color.Token.deepEmerald.opacity(showTapFeedback ? 0.85 : 0))
                    .scaleEffect(showTapFeedback ? 1.0 : 0.85)
                    .animation(.easeOut(duration: 0.2), value: showTapFeedback)
                    .allowsHitTesting(false)
            }
        }
        .clipped()
    }

    private var ornamentDot: some View {
        Circle()
            .fill(Color.Token.gold.opacity(0.5))
            .frame(width: 4, height: 4)
    }

    private func recalculateLayoutScale(availableHeight: CGFloat, contentWidth: CGFloat) {
        guard availableHeight > 0 else { return }
        let translationHeight = estimatedTranslationHeight(width: contentWidth - 72)
        let latinHeight = estimatedLatinHeight(width: contentWidth - 72)
        let budget = availableHeight - translationHeight - latinHeight - (contentSpacing * 2) - chromeInsets.top - chromeInsets.bottom
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
                .foregroundColor: UIColor(Color.Token.offWhite),
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

    private func estimatedLatinHeight(width: CGFloat) -> CGFloat {
        guard let text = verse.transliteration, !text.isEmpty else { return 0 }
        let font = UIFont.systemFont(ofSize: CGFloat(15 * effectiveFontScale), weight: .medium)
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(rect.height) + 16
    }

    private func pulseTapFeedback() {
        showTapFeedback = true
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            showTapFeedback = false
        }
    }
}
