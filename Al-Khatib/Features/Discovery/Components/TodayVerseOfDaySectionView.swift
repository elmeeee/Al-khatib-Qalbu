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

                Text(AppLanguageManager.shared.localize("verse_of_the_day"))
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
    let reciterName: String
    let isPlaying: Bool
    let onAudio: () -> Void
    let onShare: () -> Void
    let onReflect: () -> Void
    let onTafsir: () -> Void
    let audioAccessibilityHint: String

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let lang = AppLanguageManager.shared.currentLanguage
        formatter.locale = Locale(identifier: lang.rawValue)
        return formatter.string(from: Date()).capitalized
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header: Title, Subtitle & Day Pill + Share
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(AppLanguageManager.shared.localize("today_quran_title"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    if let key = verse.verseKey {
                        Text(ShareVerseCard.humanLabel(for: key))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.Token.gold)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Glassmorphic Share Button
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.Token.deepEmerald)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.Token.deepEmerald.opacity(0.08)))
                            .overlay(Circle().stroke(Color.Token.deepEmerald.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .alKhatibAccessibility(label: AppLanguageManager.shared.localize("share"), hint: AlKhatibAccessibility.VerseActions.shareHint)
                    
                    // Day of the Week Badge
                    Text(dayName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.orange.opacity(0.1)))
                        .overlay(Capsule().stroke(Color.orange.opacity(0.25), lineWidth: 1))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            // Arabic Text Block Container
            VStack {
                AyahArabicWebBlock(
                    payload: verse,
                    includeTranslationInAccessibility: showTranslation
                )
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: Color.Token.deepEmerald.opacity(0.04), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.Token.deepEmerald.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 16)

            // Transliteration / Latin Block
            if let latinText = verse.transliteration, latinText.isEmpty == false {
                Text(latinText)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(Color.Token.deepEmerald.opacity(0.85))
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.Token.mintWash.opacity(0.35))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.Token.deepEmerald.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
            }

            // Translation Block
            if showTranslation,
               let translation = verse.translations?.first,
               let text = translation.text,
               text.isEmpty == false {
                VStack(alignment: .leading, spacing: 0) {
                    Text(text)
                        .font(.system(size: 15, weight: .regular))
                        .lineSpacing(5)
                        .foregroundColor(Color.Token.slate800)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.45))
                )
                .padding(.horizontal, 16)
            }

            // Qari Reciter Info
            if reciterName.isEmpty == false {
                HStack(spacing: 6) {
                    Image(systemName: "headphones")
                        .font(.system(size: 12))
                        .foregroundColor(Color.Token.gold)
                    
                    Text("\(AppLanguageManager.shared.localize("qari_label")): \(reciterName)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color.Token.deepEmerald.opacity(0.8))
                }
                .padding(.top, 4)
            }

            // Action Buttons Row (Audio, AI, Tafsir)
            HStack(spacing: 12) {
                // Audio
                actionButton(
                    icon: isPlaying ? "pause.fill" : "play.fill",
                    text: "Audio",
                    tint: Color.Token.deepEmerald,
                    background: LinearGradient(
                        colors: [Color.Token.deepEmerald.opacity(0.12), Color.Token.teal.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    action: onAudio
                )
                .alKhatibAccessibility(label: "Audio", hint: audioAccessibilityHint)
                
                // AI
                actionButton(
                    icon: "sparkles",
                    text: "AI",
                    tint: Color.orange,
                    background: LinearGradient(
                        colors: [Color.orange.opacity(0.12), Color.Token.gold.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    action: onReflect
                )
                .alKhatibAccessibility(label: "AI Reflection", hint: AlKhatibAccessibility.VerseActions.reflectHint)
                
                // Tafsir
                actionButton(
                    icon: "book.closed.fill",
                    text: "Tafsir",
                    tint: Color.Token.indigoAccent,
                    background: LinearGradient(
                        colors: [Color.Token.indigoAccent.opacity(0.12), Color.purple.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    action: onTafsir
                )
                .alKhatibAccessibility(label: "Tafsir", hint: AlKhatibAccessibility.VerseActions.tafsirHint)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .transaction { txn in txn.animation = nil }
        .opacity(isDetailLoading ? 0.55 : 1)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.85), Color.Token.mintWash.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.Token.deepEmerald.opacity(0.12), Color.Token.softGrey.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.Token.deepEmerald.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    private func actionButton(
        icon: String,
        text: String,
        tint: Color,
        background: LinearGradient,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(text)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(background)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(tint.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PillPressStyle())
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
        let lm = AppLanguageManager.shared
        LazyVGrid(columns: columns, spacing: 8) {
            TodayActionPill(icon: "speaker.wave.2.fill", text: "Audio", tint: Color.Token.deepEmerald, hint: audioAccessibilityHint, action: onAudio)
            TodayActionPill(icon: "square.and.arrow.up", text: lm.localize("share"), tint: Color.Token.blueLink, hint: AlKhatibAccessibility.VerseActions.shareHint, action: onShare)
            TodayActionPill(icon: "lightbulb.fill", text: lm.localize("post_reflection"), tint: Color.Token.gold, hint: AlKhatibAccessibility.VerseActions.reflectHint, action: onReflect)
            TodayActionPill(icon: "book.closed.fill", text: lm.localize("tab_quran"), tint: Color.Token.indigoAccent, hint: AlKhatibAccessibility.VerseActions.tafsirHint, action: onTafsir)
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
