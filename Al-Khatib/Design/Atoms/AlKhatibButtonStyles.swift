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
            .background(Color.Token.deepEmerald.opacity(configuration.isPressed ? 0.85 : 1.0))
            .cornerRadius(12)
            .animation(.none, value: configuration.isPressed)
    }
}

struct GhostFlatButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .foregroundColor(Color.Token.deepEmerald)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(Color.Token.pureWhite)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.Token.softGrey, lineWidth: 1)
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

struct PillPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PillPressStyle {
    static var pillPress: PillPressStyle { PillPressStyle() }
}
