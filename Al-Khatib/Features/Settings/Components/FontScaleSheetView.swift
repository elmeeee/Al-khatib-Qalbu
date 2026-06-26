//
//  FontScaleSheetView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct FontScaleSheetView: View {
    @Binding var fontScale: Double
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = AppLanguageManager.shared

    private let fontScaleRange: ClosedRange<Double> = 0.85 ... 1.35

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(languageManager.localize("sample_arabic_typography"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                        .font(.system(size: 26 * fontScale, weight: .semibold, design: .serif))
                        .foregroundColor(Color.Token.deepEmerald)
                        .multilineTextAlignment(.center)

                    Text(languageManager.localize("basmalah_translation"))
                        .font(.system(size: 14 * fontScale))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(Color.Token.lightGrey, in: RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 16) {
                    Text("A")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)

                    Slider(value: $fontScale, in: fontScaleRange, step: 0.05)
                        .tint(Color.Token.teal)

                    Text("A")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)

                Text(fontScaleLabel)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.Token.teal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.Token.teal.opacity(0.1))
                    .clipShape(Capsule())

                Button {
                    dismiss()
                } label: {
                    Text(languageManager.localize("done"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.Token.teal)
                        .clipShape(Capsule())
                }
                .padding(.top, 12)
            }
            .padding(24)
            .navigationTitle(languageManager.localize("font_size"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(languageManager.localize("close")) { dismiss() }
                        .tint(Color.Token.teal)
                }
            }
        }
        .presentationDetents([.fraction(0.55)])
    }

    private var fontScaleLabel: String {
        switch fontScale {
        case ..<0.95: languageManager.localize("font_small")
        case 0.95 ..< 1.1: languageManager.localize("font_medium")
        case 1.1 ..< 1.22: languageManager.localize("font_large")
        default: languageManager.localize("font_extra_large")
        }
    }
}
