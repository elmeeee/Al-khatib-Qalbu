//
//  ProfileRowView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

/// A single settings row — Apple Settings style with a colored icon square.
struct ProfileRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let hasToggle: Bool
    /// Optional tint for the icon background — defaults to teal
    var iconTint: Color = Color.Token.teal
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            // ── Icon ────────────────────────────────────────────────
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconTint)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            // ── Labels ───────────────────────────────────────────────
            if hasToggle {
                Toggle(isOn: $isOn) {
                    labelStack
                }
                .tint(Color.Token.teal)
            } else {
                labelStack
                Spacer()
                if subtitle.isEmpty == false {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.Token.slate400)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.Token.softGrey)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: hasToggle ? .ignore : .combine)
        .accessibilityLabel(
            hasToggle
                ? AlKhatibAccessibility.Profile.toggle(title, subtitle: subtitle, isOn: isOn)
                : "\(title). \(subtitle)"
        )
    }

    private var labelStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.Token.slate900)
            if subtitle.isEmpty == false && !hasToggle {
                EmptyView() // subtitle shown inline on right for nav rows
            } else if subtitle.isEmpty == false {
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }
}
