//
//  PrayerTimeColumn.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct PrayerTimeColumn: View {
    let name: String
    let time: String
    let isActive: Bool
    let theme: PrayerThematicTheme
    
    init(name: String, time: String, isActive: Bool, theme: PrayerThematicTheme) {
        self.name = name
        self.time = time
        self.isActive = isActive
        self.theme = theme
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Group {
                if name == "Fajr" {
                    Image(systemName: "cloud.moon.fill")
                } else if name == "Sunrise" {
                    Image(systemName: "cloud.sun.fill")
                } else if name == "Dhuhr" {
                    Image(systemName: "sun.max.fill")
                } else if name == "Asr" {
                    Image(systemName: "sun.and.horizon.fill")
                } else if name == "Maghrib" {
                    Image(systemName: "sunset.fill")
                } else if name == "Isha" {
                    Image(systemName: "moon.fill")
                } else {
                    Image(systemName: "clock.fill")
                }
            }
            .font(.system(size: 16))
            .foregroundColor(isActive ? .white : .white.opacity(0.6))
            
            Text(time)
                .font(.system(size: 12, weight: isActive ? .bold : .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            
            Text(name)
                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .white : .white.opacity(0.6))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(
            Group {
                if isActive {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                } else {
                    Color.clear
                }
            }
        )
        .scaleEffect(isActive ? 1.04 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0), value: isActive)
        .onChange(of: isActive) { oldValue, newValue in
            if newValue {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            }
        }
    }
}
