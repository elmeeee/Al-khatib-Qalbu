//
//  PrayerTrackerCalendarView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct PrayerTrackerCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appContainer) private var container
    
    @State private var currentYear = Calendar.current.component(.year, from: Date())
    @State private var currentMonth = Calendar.current.component(.month, from: Date())
    
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var daysProgress: [PrayerDayProgress] = []
    
    private let calendar = Calendar.current
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"
        return formatter.monthSymbols[currentMonth - 1]
    }
    
    private var shiftedWeekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }
    
    private var daysInMonthGrid: [Date?] {
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = currentMonth
        comps.day = 1
        guard let firstOfMonth = calendar.date(from: comps) else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingEmptyCells = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        guard let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }
        let numDays = range.count
        
        var grid: [Date?] = Array(repeating: nil, count: leadingEmptyCells)
        for day in 1...numDays {
            var dayComps = DateComponents()
            dayComps.year = currentYear
            dayComps.month = currentMonth
            dayComps.day = day
            if let date = calendar.date(from: dayComps) {
                grid.append(date)
            }
        }
        return grid
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.Token.deepEmerald)
                }
                .accessibilityLabel("Back")
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Prayer Tracker History")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.Token.slate800)
                    
                    Text("Check your monthly completion rate")
                        .font(.system(size: 11))
                        .foregroundColor(Color.Token.slate500)
                }
                
                Spacer()
                
                Color.clear.frame(width: 20, height: 20)
            }
            .padding()
            .background(Color.Token.pureWhite)
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Challenge stats card
                    VStack(spacing: 16) {
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(Color.Token.goldDeep)
                                        .font(.system(size: 18))
                                    
                                    Text("\(streak)")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(Color.Token.deepEmerald)
                                }
                                
                                Text("Current streak")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.Token.slate500)
                            }
                            
                            Spacer()
                            
                            Divider().frame(height: 35)
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trophy.fill")
                                        .foregroundColor(Color.Token.goldDeep)
                                        .font(.system(size: 16))
                                    
                                    Text("\(bestStreak)")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(Color.Token.deepEmerald)
                                }
                                
                                Text("Best streak")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.Token.slate500)
                            }
                            
                            Spacer()
                        }
                        
                        // Next Challenge text
                        let target = challengeTarget(for: streak)
                        VStack(spacing: 4) {
                            Text("Next Challenge Target: \(target) days")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.Token.deepEmerald)
                            
                            ProgressView(value: min(Double(streak), Double(target)), total: Double(target))
                                .tint(Color.Token.deepEmerald)
                                .padding(.horizontal, 10)
                        }
                        .padding(.top, 4)
                    }
                    .padding(18)
                    .background(Color.Token.pureWhite)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // Month shifting controls
                    HStack {
                        Button(action: { shiftMonth(by: -1) }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.Token.deepEmerald)
                                .padding(8)
                        }
                        
                        Spacer()
                        
                        Text("\(monthName) \(String(currentYear))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.Token.slate800)
                        
                        Spacer()
                        
                        Button(action: { shiftMonth(by: 1) }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.Token.deepEmerald)
                                .padding(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Grid card
                    VStack(spacing: 12) {
                        // Weekday Headers
                        HStack(spacing: 0) {
                            ForEach(shiftedWeekdaySymbols, id: \.self) { symbol in
                                Text(symbol)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color.Token.slate400)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        // Days grid
                        let grid = daysInMonthGrid
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
                        
                        LazyVGrid(columns: columns, spacing: 6) {
                            ForEach(0..<grid.count, id: \.self) { index in
                                if let date = grid[index] {
                                    let dayNum = calendar.component(.day, from: date)
                                    let isToday = calendar.isDateInToday(date)
                                    
                                    // Fetch progress
                                    let progress = dayProgress(for: date)
                                    let complete = progress.isPerfectDay
                                    let partial = progress.completedCount > 0
                                    
                                    VStack {
                                        Spacer()
                                        
                                        Text("\(dayNum)")
                                            .font(.system(size: 14, weight: isToday ? .bold : .semibold))
                                            .foregroundColor(complete ? .white : (partial ? Color.Token.deepEmerald : Color.Token.slate500))
                                        
                                        if complete {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                        } else if partial {
                                            Text("\(progress.completedCount)/\(progress.totalCount)")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(Color.Token.deepEmerald)
                                        } else {
                                            Spacer().frame(height: 11)
                                        }
                                        
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1.0, contentMode: .fit)
                                    .background(
                                        Group {
                                            if complete {
                                                LinearGradient(
                                                    colors: [Color.Token.deepEmerald, Color.Token.teal],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            } else if partial {
                                                Color.Token.teal.opacity(0.15)
                                            } else {
                                                Color.Token.softGrey.opacity(0.4)
                                            }
                                        }
                                    )
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isToday ? Color.Token.goldDeep : Color.clear, lineWidth: 2)
                                    )
                                } else {
                                    Color.clear
                                        .aspectRatio(1.0, contentMode: .fit)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.Token.pureWhite)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .background(Color.Token.screenBackground)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            reloadStoreData()
        }
    }
    
    private func reloadStoreData() {
        let store = PrayerTrackerStore(appGroupIdentifier: container?.configuration.appGroupIdentifier)
        streak = store.currentStreak()
        bestStreak = store.bestStreak()
        daysProgress = store.monthProgress(year: currentYear, month: currentMonth)
    }
    
    private func shiftMonth(by delta: Int) {
        if let newDate = calendar.date(byAdding: .month, value: delta, to: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!) {
            currentYear = calendar.component(.year, from: newDate)
            currentMonth = calendar.component(.month, from: newDate)
            reloadStoreData()
        }
    }
    
    private func dayProgress(for date: Date) -> PrayerDayProgress {
        let store = PrayerTrackerStore(appGroupIdentifier: container?.configuration.appGroupIdentifier)
        let key = store.dayKeyFor(date: date)
        return store.dayProgress(dayKey: key)
    }
    
    private func challengeTarget(for streak: Int) -> Int {
        if streak < 7 { return 7 }
        if streak < 30 { return 30 }
        if streak < 40 { return 40 }
        return ((streak / 10) + 1) * 10
    }
}
