//
//  PrayerCalendarView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI
import CoreLocation

struct PrayerCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var prayerController: PrayerTimesController
    
    @State private var currentYear = Calendar.current.component(.year, from: Date())
    @State private var currentMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var calendarTimings: [Int: [String: String]] = [:] // Day -> Timings
    
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
                    Text("Prayer Calendar")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.Token.slate800)
                    
                    if let city = prayerController.cityName {
                        Text(city)
                            .font(.system(size: 11))
                            .foregroundColor(Color.Token.slate500)
                    }
                }
                
                Spacer()
                
                Color.clear.frame(width: 20, height: 20)
            }
            .padding()
            .background(Color.Token.pureWhite)
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
            
            ScrollView {
                VStack(spacing: 16) {
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
                    .padding(.top, 12)
                    
                    // Calendar grid card
                    VStack(spacing: 12) {
                        // Weekday Headers
                        HStack(spacing: 0) {
                            ForEach(0..<shiftedWeekdaySymbols.count, id: \.self) { index in
                                Text(shiftedWeekdaySymbols[index])
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color.Token.slate400)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        // Days grid
                        let grid = daysInMonthGrid
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(0..<grid.count, id: \.self) { index in
                                if let date = grid[index] {
                                    let dayNum = calendar.component(.day, from: date)
                                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                                    let isToday = calendar.isDateInToday(date)
                                    let khgtInfo = LocalKhgtCalendar.shared.infoForDate(date)
                                    let isImportant = khgtInfo?.isImportantDay == true
                                    
                                    Button(action: { selectedDate = date }) {
                                        VStack(spacing: 4) {
                                            Text("\(dayNum)")
                                                .font(.system(size: 15, weight: isSelected ? .bold : (isToday ? .bold : .semibold)))
                                                .foregroundColor(isSelected ? .white : (isToday ? Color.Token.deepEmerald : Color.Token.slate800))
                                                .frame(width: 32, height: 32)
                                                .background(isSelected ? Color.Token.deepEmerald : (isToday ? Color.Token.deepEmerald.opacity(0.1) : Color.clear))
                                                .clipShape(Circle())
                                            
                                            // Tiny dot for important days
                                            Circle()
                                                .fill(isImportant ? Color.Token.goldDeep : Color.clear)
                                                .frame(width: 4, height: 4)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    Color.clear
                                        .frame(height: 40)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.Token.pureWhite)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView()
                            .padding(.vertical, 30)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { Task { await fetchMonthData() } }) {
                                Text("Retry")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.Token.deepEmerald)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 20)
                    } else {
                        // Selected Day Info & Timings
                        VStack(alignment: .leading, spacing: 16) {
                            let khgt = LocalKhgtCalendar.shared.infoForDate(selectedDate)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(selectedDateLabel())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color.Token.slate800)
                                    
                                    Spacer()
                                    
                                    if let pasaran = khgt?.pasaran {
                                        Text(pasaran)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color.Token.slate500)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.Token.softGrey.opacity(0.4))
                                            .cornerRadius(4)
                                    }
                                }
                                
                                if let hijri = khgt?.hijriLabel {
                                    Text(hijri)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.Token.deepEmerald)
                                }
                            }
                            
                            // Important Hijri Event Banner
                            if let event = khgt?.eventTitle {
                                HStack(spacing: 10) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(Color.Token.goldDeep)
                                        .font(.system(size: 14))
                                    
                                    Text(event)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color.Token.slate800)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.Token.goldDeep.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            // Prayer Timings List
                            VStack(spacing: 0) {
                                let list = prayerTimingsList()
                                ForEach(0..<list.count, id: \.self) { idx in
                                    let item = list[idx]
                                    HStack {
                                        Text(item.0)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color.Token.slate700)
                                        
                                        Spacer()
                                        
                                        Text(item.1)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(Color.Token.slate800)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(idx % 2 == 0 ? Color.clear : Color.Token.softGrey.opacity(0.15))
                                    
                                    if idx < list.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.Token.softGrey.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .padding()
                        .background(Color.Token.pureWhite)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color.Token.screenBackground)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await fetchMonthData()
        }
    }
    
    private func shiftMonth(by delta: Int) {
        if let newDate = calendar.date(byAdding: .month, value: delta, to: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!) {
            currentYear = calendar.component(.year, from: newDate)
            currentMonth = calendar.component(.month, from: newDate)
            
            // Adjust selected day
            let today = Date()
            if calendar.component(.year, from: today) == currentYear && calendar.component(.month, from: today) == currentMonth {
                selectedDate = calendar.startOfDay(for: today)
            } else {
                selectedDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
            }
            
            Task {
                await fetchMonthData()
            }
        }
    }
    
    private func selectedDateLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private func prayerTimingsList() -> [(String, String)] {
        let day = calendar.component(.day, from: selectedDate)
        guard let timings = calendarTimings[day] else {
            return [
                ("Fajr", "--:--"),
                ("Sunrise", "--:--"),
                ("Dhuhr", "--:--"),
                ("Asr", "--:--"),
                ("Maghrib", "--:--"),
                ("Isha", "--:--")
            ]
        }
        
        let keys = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
        return keys.map { key in
            let rawTime = timings[key] ?? "--:--"
            let clean = rawTime.components(separatedBy: " ").first ?? rawTime
            return (key, clean)
        }
    }
    
    private func fetchMonthData() async {
        isLoading = true
        errorMessage = nil
        calendarTimings = [:]
        
        // Resolve location
        var lat = -6.2088 // Jakarta default
        var lon = 106.8456
        
        if let location = prayerController.lastKnownLocation {
            lat = location.coordinate.latitude
            lon = location.coordinate.longitude
        }
        
        let method = prayerController.calculationMethod
        
        let calendar = Calendar.current
        let comps = DateComponents(year: currentYear, month: currentMonth)
        guard let monthDate = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: monthDate) else {
            errorMessage = "Invalid month/year specifications."
            isLoading = false
            return
        }

        let tzOffset = Double(TimeZone.current.secondsFromGMT(for: Date())) / 3600.0
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = .current

        var mapped: [Int: [String: String]] = [:]
        for day in range {
            var dayComps = comps
            dayComps.day = day
            guard let dayDate = calendar.date(from: dayComps) else { continue }
            
            let dayTimings = LocalPrayerTimesCalculator.calculate(
                date: dayDate,
                latitude: lat,
                longitude: lon,
                timezoneOffset: tzOffset,
                method: method
            )
            
            var dayTimingStrings: [String: String] = [:]
            for (key, dateValue) in dayTimings {
                dayTimingStrings[key] = timeFormatter.string(from: dateValue)
            }
            mapped[day] = dayTimingStrings
        }

        calendarTimings = mapped
        errorMessage = nil
        isLoading = false
    }
}

// MARK: - API Structs
private struct AlAdhanCalendarResponse: Codable {
    let code: Int
    let status: String
    let data: [AlAdhanDayData]
}

private struct AlAdhanDayData: Codable {
    let timings: [String: String]
    let date: AlAdhanDateInfo
}

private struct AlAdhanDateInfo: Codable {
    let readable: String
    let timestamp: String
    let gregorian: AlAdhanGregorianDate
}

private struct AlAdhanGregorianDate: Codable {
    let day: String
    let month: AlAdhanMonthInfo
    let year: String
}

private struct AlAdhanMonthInfo: Codable {
    let number: Int
    let en: String
}
