//
//  ReflectReelBackgroundView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectReelBackgroundView: View {
    @Binding var ambientPhase: CGFloat

    var body: some View {
        ZStack {
            ReflectReelChrome.gradient
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    ReflectReelChrome.ambientTeal.opacity(0.15 + ambientPhase * 0.08),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 350
            )
            .allowsHitTesting(false)

            RadialGradient(
                colors: [
                    ReflectReelChrome.ambientGold.opacity(0.06 + ambientPhase * 0.04),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 280
            )
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.Token.forestDark.opacity(0.55), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.Token.forestDeeper.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                ambientPhase = 1
            }
        }
    }
}
