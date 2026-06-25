//
//  GoldPriceRepository.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

internal final class GoldPriceRepository: Sendable {
    internal static let shared = GoldPriceRepository()

    private init() {}

    internal func fetchQuote(currency: String = "IDR") async -> GoldPriceQuote? {
        do {
            if let quote = try await fetchQuoteFromLogamMulia() {
                return quote
            }
        } catch {
            print("Logam Mulia fetch failed: \(error.localizedDescription)")
        }

        do {
            if let fallback = try await fetchQuoteFallback(currency: currency) {
                return fallback
            }
        } catch {
            print("Fallback gold price fetch failed: \(error.localizedDescription)")
        }

        return nil
    }

    private func fetchQuoteFromLogamMulia() async throws -> GoldPriceQuote? {
        guard let url = URL(string: "https://logam-mulia-api.iamutaki.workers.dev/api/prices/hargaemas-net") else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let items = json["data"] as? [[String: Any]] else {
            return nil
        }

        func parseGramPrice(material: String) -> Double? {
            var fallbackWeight: Double?
            var fallbackPrice: Double?

            for item in items {
                guard let mat = item["material"] as? String, mat == material,
                      let unit = item["weightUnit"] as? String, unit == "gr",
                      let weight = item["weight"] as? Double,
                      let sellPrice = item["sellPrice"] as? Double,
                      weight > 0, sellPrice > 0 else {
                    continue
                }

                if weight == 1.0 {
                    return sellPrice
                }

                if fallbackWeight == nil || weight < fallbackWeight! {
                    fallbackWeight = weight
                    fallbackPrice = sellPrice
                }
            }

            if let fw = fallbackWeight, let fp = fallbackPrice {
                return fp / fw
            }
            return nil
        }

        let goldPrice = parseGramPrice(material: "gold")
        let silverPrice = parseGramPrice(material: "silver")

        guard let gPrice = goldPrice else { return nil }
        let sPrice = silverPrice ?? ZakatCalculator.silverPriceFromGold(goldPricePerGram: gPrice)

        return GoldPriceQuote(
            goldPerGramIdr: gPrice,
            silverPerGramIdr: sPrice,
            sourceLabel: "Logam Mulia / Harga Emas.net",
            fetchedAtMillis: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }

    private func fetchQuoteFallback(currency: String) async throws -> GoldPriceQuote? {
        guard let goldUsdOz = try await fetchGoldUsdPerTroyOz() else { return nil }
        guard let usdRate = try await fetchUsdRate(targetCurrency: currency) else { return nil }

        let goldPerGramLocal = ZakatCalculator.goldUsdPerGram(usdPerTroyOz: goldUsdOz) * usdRate
        let silverPerGramLocal = goldPerGramLocal / 80.0

        return GoldPriceQuote(
            goldPerGramIdr: goldPerGramLocal,
            silverPerGramIdr: silverPerGramLocal,
            sourceLabel: "metals.live + open.er-api.com",
            fetchedAtMillis: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }

    private func fetchGoldUsdPerTroyOz() async throws -> Double? {
        guard let url = URL(string: "https://api.metals.live/v1/spot/gold") else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        if let array = try JSONSerialization.jsonObject(with: data) as? [[Any]],
           let first = array.first,
           first.count > 1 {
            if let priceStr = first[1] as? String {
                return Double(priceStr)
            } else if let priceNum = first[1] as? Double {
                return priceNum
            }
        }
        return nil
    }

    private func fetchUsdRate(targetCurrency: String) async throws -> Double? {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? String, result == "success",
              let rates = json["rates"] as? [String: Any],
              let rate = rates[targetCurrency] as? Double else {
            return nil
        }
        return rate
    }
}
