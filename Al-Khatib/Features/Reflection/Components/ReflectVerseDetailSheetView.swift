//
//  ReflectVerseDetailSheetView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectVerseDetailSheetView: View {
    let verseKey: String
    let response: SingleVerseResponse?
    let isLoading: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.Token.forestDeeper,
                    Color.Token.forestDark,
                    Color.Token.deepEmerald
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if isLoading && response == nil {
                verseLoadingState
            } else if let verse = response?.verse {
                verseContentView(verse: verse)
            } else if !isLoading {
                verseErrorState
            }
        }
    }

    private var verseLoadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Color.Theme.gold)
                .scaleEffect(1.2)
            Text("Loading verse…")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var verseErrorState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.white.opacity(0.5))
            Text("Could not load verse")
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.8))
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.Theme.deepEmerald)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(.white)
                    .clipShape(Capsule())
            }
        }
    }

    private func verseContentView(verse: RandomAyahPayload) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(VerseKeyFormat.humanLabel(for: verseKey))
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(Color.Theme.gold)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [
                                Color.Theme.gold.opacity(0.2),
                                Color.Theme.gold.opacity(0.08)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.Theme.gold.opacity(0.3), lineWidth: 0.5)
                )

                ornamentalDivider

                if let arabicText = verse.displayText, arabicText.isEmpty == false {
                    VStack(spacing: 8) {
                        Text(arabicText)
                            .font(AlKhatibTypography.quranArabic(size: 28))
                            .multilineTextAlignment(.center)
                            .environment(\.layoutDirection, .rightToLeft)
                            .lineSpacing(12)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                    }
                }

                ornamentalDivider

                if let translations = verse.translations, translations.isEmpty == false {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(translations, id: \.id) { translation in
                            VStack(alignment: .leading, spacing: 6) {
                                if let name = translation.resourceName, name.isEmpty == false {
                                    Text(name)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.Theme.gold.opacity(0.7))
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                }

                                if let text = translation.text {
                                    let cleaned = text.strippingHTMLToPlainText()
                                    Text(cleaned)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(.white.opacity(0.85))
                                        .lineSpacing(4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 32)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
    }

    private var ornamentalDivider: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.Theme.gold.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
            Text("\u{2726}")
                .font(.system(size: 10))
                .foregroundStyle(Color.Theme.gold.opacity(0.5))
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.Theme.gold.opacity(0.2), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
        }
        .padding(.horizontal, 32)
    }
}
