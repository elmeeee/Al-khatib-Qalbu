//
//  ZakatCalculator.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum ZakatType: String, CaseIterable, Codable, Sendable {
    case maal = "MAAL"
    case fitrah = "FITRAH"
}

struct ZakatMaalCalculationResult: Codable, Sendable {
    let zakatableWealth: Double
    let nisabGoldGrams: Double
    let nisabSilverGrams: Double
    let nisabGoldValue: Double
    let nisabSilverValue: Double
    let effectiveNisab: Double
    let zakatDue: Double
    let meetsNisab: Bool
    let usedSilverNisab: Bool
}

struct ZakatFitrahCalculationResult: Codable, Sendable {
    let familyMembers: Int
    let stapleWeightPerPersonKg: Double
    let staplePricePerKg: Double
    let totalStapleKilograms: Double
    let zakatDue: Double
}

struct GoldPriceQuote: Codable, Sendable {
    let goldPerGramIdr: Double
    let silverPerGramIdr: Double
    let sourceLabel: String
    let fetchedAtMillis: Int64
}

enum ZakatCountry: String, CaseIterable, Codable, Sendable {
    case indonesia = "ID"
    case malaysia = "MY"
    case singapore = "SG"
    case brunei = "BN"
}

struct ZakatCalculator {
    static let NISAB_GOLD_GRAMS = 85.0
    static let NISAB_SILVER_GRAMS = 595.0
    static let ZAKAT_RATE = 0.025
    static let FITRAH_WEIGHT_PER_PERSON_KG = 2.5
    private static let TROY_OZ_GRAMS = 31.1034768

    static func goldUsdPerGram(usdPerTroyOz: Double) -> Double {
        return usdPerTroyOz / TROY_OZ_GRAMS
    }

    static func calculate(
        cash: Double,
        goldGrams: Double,
        silverGrams: Double,
        investments: Double,
        debts: Double,
        goldPricePerGram: Double,
        silverPricePerGram: Double
    ) -> ZakatMaalCalculationResult {
        let goldValue = goldGrams * goldPricePerGram
        let silverValue = silverGrams * silverPricePerGram
        let net = max(0.0, cash + goldValue + silverValue + investments - debts)
        let nisabGoldVal = NISAB_GOLD_GRAMS * goldPricePerGram
        let nisabSilverVal = NISAB_SILVER_GRAMS * silverPricePerGram
        let effectiveNisab = min(nisabGoldVal, nisabSilverVal)
        let usedSilver = nisabSilverVal < nisabGoldVal
        let meetsNisab = net >= effectiveNisab
        let zakatDue = meetsNisab ? floor(net * ZAKAT_RATE * 100.0) / 100.0 : 0.0
        
        return ZakatMaalCalculationResult(
            zakatableWealth: net,
            nisabGoldGrams: NISAB_GOLD_GRAMS,
            nisabSilverGrams: NISAB_SILVER_GRAMS,
            nisabGoldValue: nisabGoldVal,
            nisabSilverValue: nisabSilverVal,
            effectiveNisab: effectiveNisab,
            zakatDue: zakatDue,
            meetsNisab: meetsNisab,
            usedSilverNisab: usedSilver
        )
    }

    static func calculateFitrah(
        familyMembers: Int,
        staplePricePerKg: Double,
        stapleWeightPerPersonKg: Double = FITRAH_WEIGHT_PER_PERSON_KG
    ) -> ZakatFitrahCalculationResult {
        let totalWeight = Double(familyMembers) * stapleWeightPerPersonKg
        let zakatDue = floor(totalWeight * staplePricePerKg * 100.0) / 100.0
        
        return ZakatFitrahCalculationResult(
            familyMembers: familyMembers,
            stapleWeightPerPersonKg: stapleWeightPerPersonKg,
            staplePricePerKg: staplePricePerKg,
            totalStapleKilograms: totalWeight,
            zakatDue: zakatDue
        )
    }

    static func silverPriceFromGold(goldPricePerGram: Double) -> Double {
        return goldPricePerGram / 80.0
    }
}
