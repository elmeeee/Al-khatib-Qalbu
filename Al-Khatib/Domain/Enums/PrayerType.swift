//
//  PrayerType.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

public enum PrayerType: String, CaseIterable, Identifiable, Sendable {
    case fajr = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    public var id: String { rawValue }

    public var aladhanKey: String {
        switch self {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }
    
    public static func from(aladhanKey: String) -> PrayerType? {
        switch aladhanKey {
        case "Fajr": return .fajr
        case "Sunrise": return .sunrise
        case "Dhuhr": return .dhuhr
        case "Asr": return .asr
        case "Maghrib": return .maghrib
        case "Isha": return .isha
        default: return nil
        }
    }
}
