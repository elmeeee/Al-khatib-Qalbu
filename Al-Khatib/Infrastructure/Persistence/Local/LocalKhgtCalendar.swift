//
//  LocalKhgtCalendar.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct KhgtCalendarResponse: Codable, Sendable {
    let success: Bool?
    let message: String?
    let data: [KhgtMonth]?
    let specialDays: [KhgtSpecialDay]?

    enum CodingKeys: String, CodingKey {
        case success, message, data
        case specialDays = "special_days"
    }
}

struct KhgtMonth: Codable, Sendable {
    let name: String?
    let year: Int?
    let masehiRange: String?
    let days: [KhgtDay]?

    enum CodingKeys: String, CodingKey {
        case name, year
        case masehiRange = "masehi_range"
        case days
    }
}

struct KhgtDay: Codable, Sendable {
    let masehi: String?
    let masehiShort: String?
    let hijri: String?
    let pasaran: String?
    let tooltip: String?
    let isEvent: Bool?

    enum CodingKeys: String, CodingKey {
        case masehi
        case masehiShort = "masehi_short"
        case hijri, pasaran, tooltip
        case isEvent = "is_event"
    }
}

struct KhgtSpecialDay: Codable, Sendable {
    let tanggalHijri: String?
    let tanggalMasehi: String?
    let keterangan: String?

    enum CodingKeys: String, CodingKey {
        case tanggalHijri = "tanggal_hijri"
        case tanggalMasehi = "tanggal_masehi"
        case keterangan
    }
}

struct KhgtTodayInfo: Codable, Hashable, Sendable {
    let hijriLabel: String
    let gregorianLabel: String
    let pasaran: String?
    let eventTitle: String?
    let isImportantDay: Bool
}

internal final class LocalKhgtCalendar: Sendable {
    internal static let shared = LocalKhgtCalendar()

    private init() {}

    internal func todayInfo() -> KhgtTodayInfo? {
        return infoForDate(Date())
    }

    internal func infoForDate(_ date: Date) -> KhgtTodayInfo? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "dd-MMM-yyyy"
        let gregorian = formatter.string(from: date)

        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale.current
        displayFormatter.dateFormat = "dd MMM yyyy"
        let gregorianShort = displayFormatter.string(from: date)

        // Guess Hijri year
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let hijriYear = hijriCalendar.component(.year, from: date)

        // Search in adjacent years if guess is slightly off due to moon sighting
        for year in [hijriYear, hijriYear + 1, hijriYear - 1] {
            guard let calResponse = loadYear(year) else { continue }
            guard let months = calResponse.data else { continue }

            for month in months {
                guard let days = month.days else { continue }
                if let day = days.first(where: { $0.masehi == gregorian }) {
                    let hijriLabel = "\(day.hijri ?? "") \(month.name ?? "") \(year)".trimmingCharacters(in: .whitespacesAndNewlines)
                    let event = (day.isEvent == true && !(day.tooltip ?? "").isEmpty) ? day.tooltip : nil
                    return KhgtTodayInfo(
                        hijriLabel: hijriLabel,
                        gregorianLabel: gregorianShort,
                        pasaran: day.pasaran,
                        eventTitle: event,
                        isImportantDay: event != nil
                    )
                }
            }
        }
        return nil
    }

    internal func monthForToday() -> KhgtMonth? {
        let date = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "dd-MMM-yyyy"
        let gregorian = formatter.string(from: date)

        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let hijriYear = hijriCalendar.component(.year, from: date)

        for year in [hijriYear, hijriYear + 1, hijriYear - 1] {
            guard let calResponse = loadYear(year) else { continue }
            guard let months = calResponse.data else { continue }

            for month in months {
                if month.days?.contains(where: { $0.masehi == gregorian }) == true {
                    return month
                }
            }
        }
        return nil
    }

    private func loadYear(_ hijriYear: Int) -> KhgtCalendarResponse? {
        let filename = "khgt_\(hijriYear)"
        // Support flat or subdirectory structures
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") ??
                        Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "hijri") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(KhgtCalendarResponse.self, from: data)
        } catch {
            print("Failed to decode Hijri calendar for \(hijriYear): \(error.localizedDescription)")
            return nil
        }
    }
}
