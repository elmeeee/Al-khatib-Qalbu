//
//  AlKhatibButtonStyles.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct PrimaryFlatButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(Color.Theme.deepEmerald.opacity(configuration.isPressed ? 0.85 : 1.0))
            .cornerRadius(12)
            .animation(.none, value: configuration.isPressed)
    }
}

struct GhostFlatButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .foregroundColor(Color.Theme.deepEmerald)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(Color.Theme.pureWhite)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.Theme.softGrey, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.none, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryFlatButtonStyle {
    static var primaryFlat: PrimaryFlatButtonStyle { PrimaryFlatButtonStyle() }
}

extension ButtonStyle where Self == GhostFlatButtonStyle {
    static var ghostFlat: GhostFlatButtonStyle { GhostFlatButtonStyle() }
}
