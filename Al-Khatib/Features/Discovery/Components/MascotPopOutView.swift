//
//  MascotPopOutView.swift
//  Al-Khatib
//
//  Created by Antigravity on 20/05/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct MascotPopOutView: View {
    let theme: ThematicTheme
    
    init(theme: ThematicTheme) {
        self.theme = theme
    }
    
    var body: some View {
        ZStack {
            if hasAsset(named: theme.mascotImageName) {
                Image(theme.mascotImageName)
                    .resizable()
                    .scaledToFit()
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 4)
            }
        }
    }
    
    private func hasAsset(named name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #else
        return false
        #endif
    }
    
    @ViewBuilder
    private var premiumVectorFallback: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: theme == .daylight ? [Color(hex: "#FFFDF4"), Color(hex: "#FEF3C7").opacity(0.8), Color.clear] : [Color(hex: "#4F46E5").opacity(0.35), Color(hex: "#312E81").opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 75
                    )
                )
                .frame(width: 150, height: 150)
                
            // Glassmorphic Arch Base
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(theme == .daylight ? 0.35 : 0.08))
                .frame(width: 110, height: 110)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: theme == .daylight ? [Color.white.opacity(0.7), Color.white.opacity(0.2)] : [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
            
            // Dome cutout style lines
            Path { path in
                path.move(to: CGPoint(x: 55, y: 15))
                path.addQuadCurve(to: CGPoint(x: 15, y: 55), control: CGPoint(x: 25, y: 18))
                path.addLine(to: CGPoint(x: 15, y: 95))
                path.addLine(to: CGPoint(x: 95, y: 95))
                path.addLine(to: CGPoint(x: 95, y: 55))
                path.addQuadCurve(to: CGPoint(x: 55, y: 15), control: CGPoint(x: 85, y: 18))
            }
            .fill(
                LinearGradient(
                    colors: theme == .daylight ? [Color(hex: "#FEF3C7").opacity(0.5), Color(hex: "#FDE68A").opacity(0.1)] : [Color(hex: "#4F46E5").opacity(0.2), Color(hex: "#312E81").opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 110, height: 110)
            .offset(x: -55, y: -55) // Center the path inside frame
            
            // Celestial object (Sun or Moon)
            if theme == .daylight {
                // Shiny Sun
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#F59E0B"), Color(hex: "#FCD34D")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .shadow(color: Color(hex: "#F59E0B").opacity(0.35), radius: 6, x: 0, y: 3)
                    .offset(x: 22, y: -22)
            } else {
                // Crescent Moon
                ZStack {
                    Circle()
                        .fill(Color(hex: "#E2E8F0"))
                        .frame(width: 30, height: 30)
                        .shadow(color: Color(hex: "#38BDF8").opacity(0.3), radius: 6, x: 0, y: 2)
                    
                    Circle()
                        .fill(Color(hex: "#1E293B")) // Cutout color to form crescent shape
                        .frame(width: 26, height: 26)
                        .offset(x: -7, y: -4)
                }
                .offset(x: 22, y: -22)
            }
            
            // The mascot (A gorgeous cultural stylized sheep/goat avatar)
            ZStack {
                // Mascot Body (Fluffy wool cloud layers)
                Group {
                    Circle().fill(Color(hex: theme == .daylight ? "#F3F4F6" : "#E2E8F0")).frame(width: 48, height: 48)
                    Circle().fill(Color(hex: theme == .daylight ? "#E5E7EB" : "#CBD5E1")).frame(width: 36, height: 36).offset(x: -16, y: 10)
                    Circle().fill(Color(hex: theme == .daylight ? "#E5E7EB" : "#CBD5E1")).frame(width: 36, height: 36).offset(x: 16, y: 10)
                }
                .offset(y: 12)
                
                // Mascot Face
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color(hex: "#FED7AA")) // Soft peach skin color
                    .frame(width: 42, height: 36)
                    .offset(y: -4)
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
                
                // Hair details
                Circle().fill(Color(hex: theme == .daylight ? "#F3F4F6" : "#E2E8F0")).frame(width: 14, height: 14).offset(x: -8, y: -19)
                Circle().fill(Color(hex: theme == .daylight ? "#F3F4F6" : "#E2E8F0")).frame(width: 16, height: 16).offset(x: 0, y: -22)
                Circle().fill(Color(hex: theme == .daylight ? "#F3F4F6" : "#E2E8F0")).frame(width: 14, height: 14).offset(x: 8, y: -19)
                
                // Ears
                Capsule()
                    .fill(Color(hex: "#FDBA74"))
                    .frame(width: 10, height: 18)
                    .rotationEffect(.degrees(40))
                    .offset(x: -21, y: -6)
                
                Capsule()
                    .fill(Color(hex: "#FDBA74"))
                    .frame(width: 10, height: 18)
                    .rotationEffect(.degrees(-40))
                    .offset(x: 21, y: -6)
                
                // Eyes & Smile
                if theme == .daylight {
                    // Awake eyes
                    HStack(spacing: 12) {
                        Circle().fill(Color(hex: "#1E293B")).frame(width: 5, height: 5)
                        Circle().fill(Color(hex: "#1E293B")).frame(width: 5, height: 5)
                    }
                    .offset(y: -5)
                    
                    // Blush
                    HStack(spacing: 20) {
                        Circle().fill(Color.red.opacity(0.25)).frame(width: 6, height: 6)
                        Circle().fill(Color.red.opacity(0.25)).frame(width: 6, height: 6)
                    }
                    .offset(y: -1)
                    
                    // Cute little smile
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 6, y: 0), control: CGPoint(x: 3, y: 3))
                    }
                    .stroke(Color(hex: "#7C2D12"), lineWidth: 1.5)
                    .frame(width: 6, height: 3)
                    .offset(y: 2)
                } else {
                    // Sleeping peaceful curved eyes
                    HStack(spacing: 12) {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addQuadCurve(to: CGPoint(x: 6, y: 0), control: CGPoint(x: 3, y: 3))
                        }
                        .stroke(Color(hex: "#1E293B"), lineWidth: 1.8)
                        .frame(width: 6, height: 3)
                        
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addQuadCurve(to: CGPoint(x: 6, y: 0), control: CGPoint(x: 3, y: 3))
                        }
                        .stroke(Color(hex: "#1E293B"), lineWidth: 1.8)
                        .frame(width: 6, height: 3)
                    }
                    .offset(y: -4)
                    
                    // Peaceful sleeping mouth (tiny O shape)
                    Circle()
                        .stroke(Color(hex: "#7C2D12"), lineWidth: 1.2)
                        .frame(width: 4, height: 4)
                        .offset(y: 2)
                }
            }
        }
        .frame(width: 140, height: 140)
    }
}
