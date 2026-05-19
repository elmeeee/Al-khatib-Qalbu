//
//  OnboardingView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Image("OnboardingIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
                    .padding(.bottom, 16)
                
                VStack(spacing: 8) {
                    Text("Al Khatib")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundColor(Color.Theme.deepEmerald)
                    
                    Text("Reflect on the Quran daily.")
                        .font(.system(size: 18, weight: .medium, design: .default))
                        .foregroundColor(Color.Theme.deepEmerald)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        hasCompletedOnboarding = true
                    }) {
                        Text("Get Started")
                    }
                    .buttonStyle(.primaryFlat)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}
