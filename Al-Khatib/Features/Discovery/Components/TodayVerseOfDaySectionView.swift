//
//  TodayVerseOfDaySectionView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct TodayVerseOfDaySectionHeaderView: View {
    let verseKey: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("✦")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.Token.gold)

                Text("Verse of the Day")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.Token.deepEmerald)
                    .accessibilityAddTraits(.isHeader)

                Spacer()
            }

            if let key = verseKey {
                Text(ShareVerseCard.humanLabel(for: key))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.Token.deepEmerald.opacity(0.6))
                    .padding(.leading, 22)
                    .accessibilityAddTraits(.isHeader)
            }

            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.Token.gold, Color.Token.gold.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 80, height: 3)
                Spacer()
            }
            .padding(.top, 2)
        }
    }
}

struct TodayVerseOfDayCardView: View {
    let verse: RandomAyahPayload
    let showTranslation: Bool
    let isDetailLoading: Bool
    let onAudio: () -> Void
    let onShare: () -> Void
    let onReflect: () -> Void
    let onTafsir: () -> Void
    let audioAccessibilityHint: String

    var body: some View {
        VStack(spacing: 0) {
            if let key = verse.verseKey {
                HStack {
                    Text(ShareVerseCard.humanLabel(for: key))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.Token.deepEmerald))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }

            TodayOrnamentalDividerView()
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .accessibilityHidden(true)

            VStack(alignment: .trailing, spacing: 0) {
                AyahArabicWebBlock(
                    payload: verse,
                    includeTranslationInAccessibility: showTranslation
                )
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.Token.deepEmerald.opacity(0.03))
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            )

            if showTranslation,
               let translation = verse.translations?.first,
               let text = translation.text,
               text.isEmpty == false {
                translationBlock(text)
            }

            TodayOrnamentalDividerView()
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
                .accessibilityHidden(true)

            TodayVerseActionGrid(
                onAudio: onAudio,
                onShare: onShare,
                onReflect: onReflect,
                onTafsir: onTafsir,
                audioAccessibilityHint: audioAccessibilityHint
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .transaction { txn in txn.animation = nil }
        .opacity(isDetailLoading ? 0.55 : 1)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.Token.mintWash],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.Token.deepEmerald.opacity(0.15), Color.Token.softGrey.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.Token.deepEmerald.opacity(0.06), radius: 12, x: 0, y: 6)
    }

    private func translationBlock(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\u{201C}")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.Token.gold.opacity(0.5))
                .padding(.leading, 16)
                .offset(y: 8)

            Text(text)
                .font(.system(size: 17, weight: .regular))
                .lineSpacing(6)
                .foregroundStyle(Color.Token.slate800)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)

            HStack {
                Spacer()
                Text("\u{201D}")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color.Token.gold.opacity(0.5))
                    .padding(.trailing, 16)
                    .offset(y: -8)
            }
        }
        .padding(.bottom, 8)
    }
}

struct TodayVerseActionGrid: View {
    let onAudio: () -> Void
    let onShare: () -> Void
    let onReflect: () -> Void
    let onTafsir: () -> Void
    let audioAccessibilityHint: String

    var body: some View {
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        LazyVGrid(columns: columns, spacing: 8) {
            TodayActionPill(icon: "speaker.wave.2.fill", text: "Audio", tint: Color.Token.deepEmerald, hint: audioAccessibilityHint, action: onAudio)
            TodayActionPill(icon: "square.and.arrow.up", text: "Share", tint: Color.Token.blueLink, hint: AlKhatibAccessibility.VerseActions.shareHint, action: onShare)
            TodayActionPill(icon: "lightbulb.fill", text: "Reflect", tint: Color.Token.gold, hint: AlKhatibAccessibility.VerseActions.reflectHint, action: onReflect)
            TodayActionPill(icon: "book.closed.fill", text: "Tafsir", tint: Color.Token.indigoAccent, hint: AlKhatibAccessibility.VerseActions.tafsirHint, action: onTafsir)
        }
    }
}

struct TodayActionPill: View {
    let icon: String
    let text: String
    let tint: Color
    let hint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(text)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Capsule().fill(tint.opacity(0.08)))
            .overlay(Capsule().stroke(tint.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(PillPressStyle())
        .alKhatibAccessibility(label: text, hint: hint)
    }
}
