//
//  PrayerCalculationMethod.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

/// Aladhan prayer-time calculation presets for Southeast Asian communities.
enum PrayerCalculationMethod: String, CaseIterable, Sendable, Identifiable, Codable {
    case muhammadiyah
    case kemenag
    case muis
    case jakim
    case brunei

    static let storageKey = "prayer_calculation_method"
    static let defaultMethod: PrayerCalculationMethod = .muhammadiyah

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .muhammadiyah: "Muhammadiyah"
        case .kemenag: "Ministry of Religious Affairs (Kemenag)"
        case .muis: "Majlis Ugama Islam Singapura (MUIS)"
        case .jakim: "Jabatan Kemajuan Islam Malaysia (JAKIM)"
        case .brunei: "Majlis Ugama Islam Brunei (MUIB)"
        }
    }

    var region: String {
        switch self {
        case .muhammadiyah, .kemenag: "Indonesia"
        case .muis: "Singapore"
        case .jakim: "Malaysia"
        case .brunei: "Brunei"
        }
    }

    var subtitle: String {
        "\(displayName) · \(region)"
    }

    static var hasSavedPreference: Bool {
        UserDefaults.standard.string(forKey: storageKey) != nil
    }

    static func savedOrDefault() -> PrayerCalculationMethod {
        guard let raw = UserDefaults.standard.string(forKey: storageKey),
              let method = PrayerCalculationMethod(rawValue: raw) else {
            return defaultMethod
        }
        return method
    }

    func persist(notify: Bool = true) {
        UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
        if notify {
            NotificationCenter.default.post(name: .prayerCalculationMethodDidChange, object: nil)
        }
    }

    /// Default method from ISO 3166-1 alpha-2 country code (reverse geocode).
    static func forCountryCode(_ code: String) -> PrayerCalculationMethod {
        switch code.uppercased() {
        case "ID": return .muhammadiyah
        case "SG": return .muis
        case "MY": return .jakim
        case "BN": return .brunei
        default: return .kemenag
        }
    }

    var aladhanMethodID: Int {
        switch self {
        case .muhammadiyah: 99
        case .kemenag: 20
        case .muis: 11
        case .jakim, .brunei: 17
        }
    }

    /// Only used for custom method 99 (Muhammadiyah).
    var aladhanMethodSettings: String? {
        switch self {
        case .muhammadiyah: "18,null,18"
        default: nil
        }
    }

    var aladhanSchool: Int { 0 }

    var aladhanTune: String {
        switch self {
        case .muhammadiyah: "0,2,-1,1,1,3,0,2,0"
        case .kemenag: "0,0,-1,1,1,3,0,2,0"
        case .muis, .jakim, .brunei: "0,0,0,0,0,0,0,0,0"
        }
    }
}

extension Notification.Name {
    static let prayerCalculationMethodDidChange = Notification.Name("prayerCalculationMethodDidChange")
}
