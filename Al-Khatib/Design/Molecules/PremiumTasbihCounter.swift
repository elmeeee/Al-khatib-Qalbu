//
//  PremiumTasbihCounter.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct PremiumTasbihCounter: View {
    let count: Int
    let target: Int
    let pulseKey: Int
    let subtitle: String
    var counterSize: CGFloat = 160.0

    @State private var scale: CGFloat = 1.0

    private var progress: Double {
        return Double(count) / Double(max(1, target))
    }

    private var round: Int {
        return count == 0 ? 0 : (count - 1) / 33 + 1
    }

    private var beadIndex: Int {
        return count == 0 ? -1 : (count - 1) % 33
    }

    var body: some View {
        ZStack {
            Canvas { context, size in
                let cx = size.width / 2
                let cy = size.height / 2
                let outerRadius = min(size.width, size.height) * 0.42
                let beadRadius = min(size.width, size.height) * 0.022

                // Radial background glow
                let radialGradient = GraphicsContext.Shading.radialGradient(
                    Gradient(colors: [Color.Token.teal.opacity(0.08), Color.clear]),
                    center: CGPoint(x: cx, y: cy),
                    startRadius: 0,
                    endRadius: outerRadius * 1.15
                )
                let bgRect = CGRect(x: cx - outerRadius * 1.15, y: cy - outerRadius * 1.15, width: outerRadius * 2.3, height: outerRadius * 2.3)
                context.fill(Path(ellipseIn: bgRect), with: radialGradient)

                // Track ring
                var trackPath = Path()
                trackPath.addArc(
                    center: CGPoint(x: cx, y: cy),
                    radius: outerRadius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270),
                    clockwise: false
                )
                context.stroke(
                    trackPath,
                    with: .color(Color(hex: "#E2E8F0")),
                    style: StrokeStyle(lineWidth: min(size.width, size.height) * 0.012, lineCap: .round)
                )

                // Progress Arc
                let progressClamped = max(0.0, min(1.0, progress))
                if progressClamped > 0 {
                    var progressPath = Path()
                    progressPath.addArc(
                        center: CGPoint(x: cx, y: cy),
                        radius: outerRadius,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * progressClamped),
                        clockwise: false
                    )
                    
                    let gradient = Gradient(colors: [Color.Token.goldDeep, Color.Token.teal])
                    let shading = GraphicsContext.Shading.linearGradient(
                        gradient,
                        startPoint: CGPoint(x: cx - outerRadius, y: cy),
                        endPoint: CGPoint(x: cx + outerRadius, y: cy)
                    )
                    context.stroke(
                        progressPath,
                        with: shading,
                        style: StrokeStyle(lineWidth: min(size.width, size.height) * 0.014, lineCap: .round)
                    )
                }

                // 33 Beads
                let stringRadius = outerRadius * 0.88
                for i in 0..<33 {
                    let angleDegrees = -90.0 + (360.0 * Double(i) / 33.0)
                    let angleRad = angleDegrees * .pi / 180.0
                    let x = cx + stringRadius * CGFloat(cos(angleRad))
                    let y = cy + stringRadius * CGFloat(sin(angleRad))
                    let isImam = (i == 0)
                    let filled = (i <= beadIndex)
                    let active = (i == beadIndex)

                    let r: CGFloat
                    if isImam {
                        r = beadRadius * 1.55
                    } else if active {
                        r = beadRadius * 1.35
                    } else {
                        r = beadRadius
                    }

                    if active {
                        let glowRect = CGRect(x: x - r * 2.4, y: y - r * 2.4, width: r * 4.8, height: r * 4.8)
                        context.fill(Path(ellipseIn: glowRect), with: .color(Color.Token.goldDeep.opacity(0.25)))
                    }

                    let beadColor: Color
                    if isImam {
                        beadColor = Color.Token.deepEmerald
                    } else if filled {
                        beadColor = Color.Token.goldDeep
                    } else {
                        beadColor = Color(hex: "#CBD5E1")
                    }

                    let beadRect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: beadRect), with: .color(beadColor))
                }
            }
            .frame(width: counterSize, height: counterSize)

            // Inner surface
            Circle()
                .fill(Color.Token.pureWhite)
                .frame(width: counterSize * 0.68, height: counterSize * 0.68)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.Token.teal.opacity(0.35), Color.Token.gold.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .overlay(
                    VStack(spacing: 2) {
                        Text("\(count)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.Token.slate900)
                        
                        Text(subtitle)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color.Token.slate500)
                        
                        if round > 0 {
                            Text("×\(round)")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color.Token.teal)
                                .padding(.horizontal, 4)
                                .background(Color.Token.teal.opacity(0.05))
                                .cornerRadius(4)
                        }
                    }
                )
        }
        .scaleEffect(scale)
        .onChange(of: pulseKey) { _, _ in
            scale = 0.95
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                scale = 1.0
            }
        }
    }
}

#Preview {
    PremiumTasbihCounter(
        count: 15,
        target: 33,
        pulseKey: 0,
        subtitle: "of 33"
    )
}
