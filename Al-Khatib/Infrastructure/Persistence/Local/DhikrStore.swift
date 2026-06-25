//
//  DhikrStore.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

internal struct DhikrPreset: Identifiable, Sendable {
    internal let id: String
    internal let arabic: String
    internal let target: Int
    
    internal let labelEn: String
    internal let labelId: String
    
    internal let translitEn: String
    internal let translitId: String
    
    internal let meaningEn: String
    internal let meaningId: String
    
    internal func label(for language: String) -> String {
        return language == "id" ? labelId : labelEn
    }
    
    internal func translit(for language: String) -> String {
        return language == "id" ? translitId : translitEn
    }
    
    internal func meaning(for language: String) -> String {
        return language == "id" ? meaningId : meaningEn
    }
}

internal final class DhikrStore: Sendable {
    private static let prefsSuite = "saat_dhikr"
    private static let keyCountPrefix = "count_"
    private static let keyTotalPrefix = "total_"
    
    private static var defaults: UserDefaults {
        return UserDefaults(suiteName: prefsSuite) ?? UserDefaults.standard
    }
    
    internal static let presets: [DhikrPreset] = [
        DhikrPreset(
            id: "subhanallah",
            arabic: "سُبْحَانَ اللَّهِ",
            target: 33,
            labelEn: "SubhanAllah",
            labelId: "SubhanAllah",
            translitEn: "Subḥānallāh",
            translitId: "Subḥānallāh",
            meaningEn: "Glory be to Allah",
            meaningId: "Maha Suci Allah"
        ),
        DhikrPreset(
            id: "alhamdulillah",
            arabic: "الْحَمْدُ لِلَّهِ",
            target: 33,
            labelEn: "Alhamdulillah",
            labelId: "Alhamdulillah",
            translitEn: "Al-ḥamdu lillāh",
            translitId: "Al-ḥamdu lillāh",
            meaningEn: "All praise is for Allah",
            meaningId: "Segala puji bagi Allah"
        ),
        DhikrPreset(
            id: "allahuakbar",
            arabic: "اللَّهُ أَكْبَرُ",
            target: 34,
            labelEn: "Allahu Akbar",
            labelId: "Allahu Akbar",
            translitEn: "Allāhu akbar",
            translitId: "Allāhu akbar",
            meaningEn: "Allah is the Greatest",
            meaningId: "Allah Maha Besar"
        ),
        DhikrPreset(
            id: "istighfar",
            arabic: "أَسْتَغْفِرُ اللَّهَ",
            target: 100,
            labelEn: "Istighfar",
            labelId: "Istighfar",
            translitEn: "Astaghfirullāh",
            translitId: "Astaghfirullāh",
            meaningEn: "I seek forgiveness from Allah",
            meaningId: "Aku mohon ampun kepada Allah"
        ),
        DhikrPreset(
            id: "salawat",
            arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّد",
            target: 100,
            labelEn: "Salawat",
            labelId: "Salawat",
            translitEn: "Allāhumma ṣalli ʿalā Muḥammad",
            translitId: "Allāhumma ṣalli ʿalā Muḥammad",
            meaningEn: "O Allah, send blessings upon Muhammad",
            meaningId: "Ya Allah, limpahkan shalawat kepada Muhammad"
        )
    ]
    
    internal static func sessionCount(for presetId: String) -> Int {
        return defaults.integer(forKey: keyCountPrefix + presetId)
    }
    
    internal static func totalCount(for presetId: String) -> Int {
        return defaults.integer(forKey: keyTotalPrefix + presetId)
    }
    
    internal static func increment(for presetId: String) -> Int {
        let currentSession = sessionCount(for: presetId)
        let nextSession = currentSession + 1
        let currentTotal = totalCount(for: presetId)
        
        defaults.set(nextSession, forKey: keyCountPrefix + presetId)
        defaults.set(currentTotal + 1, forKey: keyTotalPrefix + presetId)
        
        return nextSession
    }
    
    internal static func resetSession(for presetId: String) {
        defaults.set(0, forKey: keyCountPrefix + presetId)
    }
}
