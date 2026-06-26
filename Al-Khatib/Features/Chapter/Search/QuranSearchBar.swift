//
//  QuranSearchBar.swift
//  Al-Khatib
//
//  Created by Elmee on 26/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct QuranSearchBar: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    let onClear: () -> Void

    @FocusState private var fieldFocused: Bool

    private var placeholder: String {
        AppLanguageManager.shared.localize("search_quran_placeholder")
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(fieldFocused ? Color.Token.deepEmerald : Color.Token.slate500)
                .animation(.easeInOut(duration: 0.2), value: fieldFocused)

            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundColor(Color.Token.slate900)
                .tint(Color.Token.teal)
                .focused($fieldFocused)
                .submitLabel(.search)
                .accessibilityLabel(AppLanguageManager.shared.localize("search_quran_a11y"))
                .onChange(of: fieldFocused) { _, focused in
                    isFocused = focused
                }

            if text.isEmpty == false {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.18)) {
                        onClear()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.Token.slate400)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .accessibilityLabel(AppLanguageManager.shared.localize("clear_search_a11y"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            fieldFocused
                                ? Color.Token.teal.opacity(0.5)
                                : Color.Token.softGrey.opacity(0.6),
                            lineWidth: 1.2
                        )
                )
        )
        .shadow(
            color: fieldFocused ? Color.Token.teal.opacity(0.12) : Color.black.opacity(0.04),
            radius: fieldFocused ? 8 : 4,
            y: 2
        )
        .animation(.easeInOut(duration: 0.2), value: fieldFocused)
    }
}
