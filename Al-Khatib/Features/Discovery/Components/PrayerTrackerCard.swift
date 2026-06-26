//
//  PrayerTrackerCard.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct PrayerTrackerCard: View {
    @ObservedObject var viewModel: PrayerTrackerViewModel
    let onOpenCalendar: () -> Void
    @ObservedObject private var languageManager = AppLanguageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(languageManager.localize("daily_prayer_tracker"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    Text(String(format: languageManager.localize("prayer_completed_format"), viewModel.state.todayProgress.completedCount, viewModel.state.todayProgress.totalCount))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.Token.slate500)
                }
                
                Spacer()
                
                // Streak badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.Token.goldDeep)
                    
                    Text("\(viewModel.state.streak)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.Token.goldDeep)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.Token.amberWash)
                .cornerRadius(20)
                
                Button(action: onOpenCalendar) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(Color.Token.teal)
                        .padding(8)
                }
                .accessibilityLabel("Open prayer calendar")
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            
            // Progress Bar
            ProgressView(value: Double(viewModel.state.todayProgress.completedCount), total: Double(viewModel.state.todayProgress.totalCount))
                .tint(Color.Token.teal)
                .progressViewStyle(.linear)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            
            // Check off chips
            HStack(spacing: 0) {
                ForEach(PrayerTrackerStore.TRACKED_PRAYERS) { prayer in
                    let done = viewModel.state.completedPrayers.contains(prayer)
                    let enabled = done || viewModel.state.availablePrayers.contains(prayer)
                    
                    Spacer()
                    PrayerCheckChip(
                        label: languageManager.localize("prayer_" + prayer.rawValue.lowercased()),
                        completed: done,
                        enabled: enabled,
                        onClick: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.togglePrayer(prayer)
                        }
                    )
                    Spacer()
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 12)

            // Optional habits chips
            if !viewModel.state.optionalHabits.isEmpty {
                Divider()
                    .background(Color.Token.softGrey)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.state.optionalHabits) { item in
                            OptionalHabitChip(item: item) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.toggleOptionalHabit(item.habit)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
            }
        }
        .background(Color.Token.pureWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

struct PrayerCheckChip: View {
    let label: String
    let completed: Bool
    let enabled: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            VStack(alignment: .center, spacing: 4) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            completed ? Color.Token.deepEmerald :
                            (enabled ? Color.Token.softGrey : Color.Token.softGrey.opacity(0.45)),
                            lineWidth: 2
                        )
                        .background(
                            Circle().fill(
                                completed ? Color.Token.deepEmerald :
                                (enabled ? Color.clear : Color.Token.lightGrey.opacity(0.35))
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    if completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Text(label)
                    .font(.system(size: 11, weight: completed ? .semibold : .regular))
                    .foregroundColor(
                        completed ? Color.Token.deepEmerald :
                        (enabled ? Color.Token.slate500 : Color.Token.slate500.opacity(0.45))
                    )
                    .lineLimit(1)
            }
        }
        .disabled(!enabled && !completed)
        .opacity(enabled || completed ? 1.0 : 0.55)
    }
}

struct OptionalHabitChip: View {
    let item: OptionalHabitUiItem
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 4) {
                if item.completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.Token.deepEmerald)
                }
                
                Text(item.label)
                    .font(.system(size: 11, weight: item.completed ? .semibold : .regular))
                    .foregroundColor(item.completed ? Color.Token.deepEmerald : Color.Token.slate800)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(item.completed ? Color.Token.deepEmerald.opacity(0.12) : Color.Token.lightGrey)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(item.completed ? Color.Token.deepEmerald : Color.Token.softGrey, lineWidth: 1)
            )
        }
    }
}
