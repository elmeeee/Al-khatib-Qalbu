//
//  QFSideActionButton.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct QFSideActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.Token.lightGrey)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.Token.softGrey, lineWidth: 0.5)
                    )
                Text(label)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundColor(Color.Token.slate800)
        }
        .buttonStyle(PillPressStyle())
        .alKhatibAccessibility(
            label: label,
            hint: label == "Hadith"
                ? "Show hadith narrations for this ayah"
                : AlKhatibAccessibility.VerseActions.tafsirHint
        )
    }
}
