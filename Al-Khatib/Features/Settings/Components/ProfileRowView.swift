//
//  ProfileRowView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ProfileRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let hasToggle: Bool
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.Token.softGrey.opacity(0.7), lineWidth: 1)
                    .background(Color.Token.pureWhite)
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.Token.teal)
            }

            if hasToggle == false {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.Token.slate800)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if hasToggle {
                Toggle(isOn: $isOn) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.Token.slate800)
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .tint(Color.Token.teal)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.Token.softGrey)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: hasToggle ? .ignore : .combine)
        .accessibilityLabel(
            hasToggle
                ? AlKhatibAccessibility.Profile.toggle(title, subtitle: subtitle, isOn: isOn)
                : "\(title). \(subtitle)"
        )
    }
}
