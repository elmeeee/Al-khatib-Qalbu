//
//  PrayerDashboardCard.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct PrayerDashboardCard: View {
    @ObservedObject var viewModel: PrayerDashboardViewModel
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
    init(viewModel: PrayerDashboardViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if !viewModel.mappedPrayers.isEmpty && !viewModel.isLoading {
                MascotPopOutView(theme: viewModel.activeTheme)
                    .frame(width: 100, height: 100)
                    .offset(x: -10, y: 0)
                    .transition(.scale.combined(with: .opacity))
            }
            
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.mappedPrayers.isEmpty || viewModel.isLoading {
                    PrayerDashboardSkeleton()
                } else {
                    activeCardLayout
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: viewModel.activeTheme.cardGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: viewModel.activeTheme.borderGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: viewModel.activeTheme == .daylight ? Color.Token.deepEmerald.opacity(0.08) : Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
            .padding(.top, 78)
        }
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: viewModel.activeTheme)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(prayerSpokenSummary)
        .accessibilityHint("Prayer schedule for Muslims. Countdown updates automatically.")
    }

    private var prayerSpokenSummary: String {
        guard viewModel.mappedPrayers.isEmpty == false, viewModel.isLoading == false else {
            return "Loading prayer times"
        }
        let city = viewModel.cityName ?? ""
        return "Next prayer \(viewModel.nextPrayerDisplayName) in \(viewModel.countdownString). Location \(city)."
    }
    
    @ViewBuilder
    private var activeCardLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.localize("next_prayer"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(viewModel.nextPrayerDisplayName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(viewModel.nextPrayerDisplayName) · \(viewModel.nextPrayerTime)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
                
                Text(viewModel.countdownString)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.Token.goldBright)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .shadow(color: Color.Token.goldBright.opacity(0.3), radius: 6, x: 0, y: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            
            HStack(spacing: 0) {
                ForEach(viewModel.mappedPrayers) { item in
                    PrayerTimeColumn(
                        name: item.displayName,
                        time: item.timeString,
                        isActive: item.isActive,
                        theme: viewModel.activeTheme
                    )
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.18))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
}

