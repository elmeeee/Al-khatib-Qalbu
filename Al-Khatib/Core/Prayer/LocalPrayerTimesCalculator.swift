//
//  LocalPrayerTimesCalculator.swift
//  Sāat
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct LocalPrayerTimesCalculator {
    static func calculate(
        date: Date,
        latitude: Double,
        longitude: Double,
        timezoneOffset: Double,
        method: PrayerCalculationMethod
    ) -> [String: Date] {
        let calendar = Calendar.current
        let timeZone = TimeZone(secondsFromGMT: Int(timezoneOffset * 3600.0)) ?? .current
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        comps.timeZone = timeZone
        
        let year = comps.year ?? 2000
        let month = comps.month ?? 1
        let day = comps.day ?? 1
        
        // 1. Julian Date
        var y = Double(year)
        var m = Double(month)
        if m <= 2 {
            y -= 1
            m += 12
        }
        let A = floor(y / 100.0)
        let B = 2.0 - A + floor(A / 4.0)
        let JD = floor(365.25 * (y + 4716.0)) + floor(30.6001 * (m + 1.0)) + Double(day) + B - 1524.5
        
        // 2. Calculations for Sun Position
        let D = JD - 2451545.0
        let g = (357.529 + 0.98560028 * D).truncatingRemainder(dividingBy: 360.0)
        let q = (280.459 + 0.98564736 * D).truncatingRemainder(dividingBy: 360.0)
        
        let gRad = g * .pi / 180.0
        let L = (q + 1.915 * sin(gRad) + 0.020 * sin(2.0 * gRad)).truncatingRemainder(dividingBy: 360.0)
        let LRad = L * .pi / 180.0
        
        let e = 23.439 - 0.00000036 * D
        let eRad = e * .pi / 180.0
        
        let RA = (atan2(cos(eRad) * sin(LRad), cos(LRad)) * 180.0 / .pi / 15.0).truncatingRemainder(dividingBy: 24.0)
        let normalizedRA = RA < 0 ? RA + 24.0 : RA
        
        let dRad = asin(sin(eRad) * sin(LRad))
        
        let EqT = q / 15.0 - normalizedRA
        
        // 3. Midday (Dhuhr)
        var dhuhrTransit = 12.0 + timezoneOffset - (longitude / 15.0) - EqT
        if dhuhrTransit < 0 { dhuhrTransit += 24.0 }
        if dhuhrTransit >= 24.0 { dhuhrTransit -= 24.0 }
        
        let phiRad = latitude * .pi / 180.0
        
        func hourAngle(altitude: Double) -> Double? {
            let altRad = altitude * .pi / 180.0
            let denom = cos(phiRad) * cos(dRad)
            if abs(denom) < 0.00001 { return nil }
            let cosH = (sin(altRad) - sin(phiRad) * sin(dRad)) / denom
            if cosH < -1.0 || cosH > 1.0 { return nil }
            return acos(cosH) * 180.0 / .pi / 15.0
        }
        
        // Fajr & Isha parameters based on calculation method
        var fajrAngle: Double = 18.0
        var ishaAngle: Double = 18.0
        var ishaInterval: Double? = nil
        
        switch method {
        case .muhammadiyah:
            fajrAngle = 18.0
            ishaAngle = 18.0
        case .kemenag:
            fajrAngle = 20.0
            ishaAngle = 18.0
        case .muis, .jakim, .brunei:
            fajrAngle = 20.0
            ishaAngle = 18.0
        case .karachi:
            fajrAngle = 18.0
            ishaAngle = 18.0
        case .isna:
            fajrAngle = 15.0
            ishaAngle = 15.0
        case .mwl:
            fajrAngle = 18.0
            ishaAngle = 17.0
        case .ummAlQura:
            fajrAngle = 18.5
            ishaInterval = 90.0
        case .egyptian:
            fajrAngle = 19.5
            ishaAngle = 17.5
        case .tehran:
            fajrAngle = 17.7
            ishaAngle = 14.0
        case .jafari:
            fajrAngle = 16.0
            ishaAngle = 14.0
        default:
            fajrAngle = 18.0
            ishaAngle = 17.0
        }
        
        let hSunrise = hourAngle(altitude: -0.833) ?? 6.0
        let hSunset = hourAngle(altitude: -0.833) ?? 6.0
        let hFajr = hourAngle(altitude: -fajrAngle) ?? 5.0
        let hIsha = ishaInterval == nil ? (hourAngle(altitude: -ishaAngle) ?? 6.0) : 0.0
        
        let sunriseHour = dhuhrTransit - hSunrise
        let sunsetHour = dhuhrTransit + hSunset
        let fajrHour = dhuhrTransit - hFajr
        
        let ishaHour: Double
        if let interval = ishaInterval {
            ishaHour = sunsetHour + (interval / 60.0)
        } else {
            ishaHour = dhuhrTransit + hIsha
        }
        
        let sf = 1.0 // Shafi'i / Standard
        let delta = abs(phiRad - dRad)
        let asrAltRad = atan(1.0 / (sf + tan(delta)))
        let asrAltDeg = asrAltRad * 180.0 / .pi
        let hAsr = hourAngle(altitude: asrAltDeg) ?? 3.0
        let asrHour = dhuhrTransit + hAsr
        let imsakHour = fajrHour - (10.0 / 60.0)
        
        func hourToDate(_ hour: Double) -> Date {
            var finalHour = hour
            if finalHour < 0 { finalHour += 24.0 }
            if finalHour >= 24.0 { finalHour -= 24.0 }
            
            let totalMinutes = Int(round(finalHour * 60.0))
            let h = (totalMinutes / 60) % 24
            let m = totalMinutes % 60
            
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            components.hour = h
            components.minute = m
            components.second = 0
            components.timeZone = timeZone
            
            return calendar.date(from: components) ?? date
        }
        
        var result: [String: Date] = [:]
        result["Imsak"] = hourToDate(imsakHour)
        result["Fajr"] = hourToDate(fajrHour)
        result["Sunrise"] = hourToDate(sunriseHour)
        result["Dhuhr"] = hourToDate(dhuhrTransit)
        result["Asr"] = hourToDate(asrHour)
        result["Maghrib"] = hourToDate(sunsetHour)
        result["Isha"] = hourToDate(ishaHour)
        
        // Parse and apply method tunes
        let tuneStr = method.aladhanTune
        let parts = tuneStr.split(separator: ",").map { String($0) }
        var tunes = Array(repeating: 0, count: 9)
        for i in 0..<min(parts.count, 9) {
            tunes[i] = Int(parts[i]) ?? 0
        }
        
        if let imsakDate = result["Imsak"] {
            result["Imsak"] = calendar.date(byAdding: .minute, value: tunes[0], to: imsakDate)
        }
        if let fajrDate = result["Fajr"] {
            result["Fajr"] = calendar.date(byAdding: .minute, value: tunes[1], to: fajrDate)
        }
        if let sunriseDate = result["Sunrise"] {
            result["Sunrise"] = calendar.date(byAdding: .minute, value: tunes[2], to: sunriseDate)
        }
        if let dhuhrDate = result["Dhuhr"] {
            result["Dhuhr"] = calendar.date(byAdding: .minute, value: tunes[3], to: dhuhrDate)
        }
        if let asrDate = result["Asr"] {
            result["Asr"] = calendar.date(byAdding: .minute, value: tunes[4], to: asrDate)
        }
        
        // Maghrib uses index 6 if non-zero, otherwise falls back to index 5 (Sunset)
        let maghribTune = tunes[6] != 0 ? tunes[6] : tunes[5]
        if let maghribDate = result["Maghrib"] {
            result["Maghrib"] = calendar.date(byAdding: .minute, value: maghribTune, to: maghribDate)
        }
        
        if let ishaDate = result["Isha"] {
            result["Isha"] = calendar.date(byAdding: .minute, value: tunes[7], to: ishaDate)
        }
        
        // Recalculate dependent night divisions using the tuned Fajr and Maghrib times
        let maghribDate = result["Maghrib"] ?? Date()
        let nextFajrDate = (result["Fajr"] ?? Date()).addingTimeInterval(86400)
        let nightDuration = nextFajrDate.timeIntervalSince(maghribDate)
        
        result["Midnight"] = maghribDate.addingTimeInterval(nightDuration / 2.0)
        result["Firstthird"] = maghribDate.addingTimeInterval(nightDuration / 3.0)
        result["Lastthird"] = maghribDate.addingTimeInterval(nightDuration * 2.0 / 3.0)
        
        if let midnightDate = result["Midnight"], tunes[8] != 0 {
            result["Midnight"] = calendar.date(byAdding: .minute, value: tunes[8], to: midnightDate)
        }
        
        return result
    }
}
