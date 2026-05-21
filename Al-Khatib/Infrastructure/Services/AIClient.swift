//
//  AIClient.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct AIClient: Sendable {
    func complete(
        system: String,
        user: String,
        temperature: Double = 0.35,
        session: URLSession = .shared
    ) async -> String? {
        let apiKey = Self.apiKey()
        guard apiKey.isEmpty == false else { return nil }

        let body = AIChatRequest(
            model: Self.modelName(),
            messages: [
                AIMessage(role: "system", content: system),
                AIMessage(role: "user", content: user)
            ],
            temperature: temperature
        )

        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions"),
              let data = try? JSONEncoder().encode(body) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (responseData, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            let decoded = try JSONDecoder().decode(AIChatResponse.self, from: responseData)
            let raw = decoded.choices.first?.message.content ?? ""
            let cleaned = Self.sanitizeModelOutput(raw).trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? nil : cleaned
        } catch {
            return nil
        }
    }

    private static func apiKey() -> String {
        Bundle.main.infoDictionary?["API_KEY_GROQ"] as? String ?? ""
    }

    private static func modelName() -> String {
        Bundle.main.infoDictionary?["AI_MODEL"] as? String ?? ""
    }

    private static func sanitizeModelOutput(_ raw: String) -> String {
        var text = raw
        let patterns = [
            #"(?is)<think>.*?</think>"#,
            #"(?is)<\\think>.*?</\\think>"#,
            #"(?is)\[think\].*?\[/think\]"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(text.startIndex..., in: text)
                text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
            }
        }
        return text
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "<think>", with: "")
            .replacingOccurrences(of: "</think>", with: "")
            .replacingOccurrences(of: "<\\think>", with: "")
            .replacingOccurrences(of: "</\\think>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct AIChatRequest: Encodable {
    let model: String
    let messages: [AIMessage]
    let temperature: Double
}

private struct AIMessage: Encodable {
    let role: String
    let content: String
}

private struct AIChatResponse: Decodable {
    let choices: [AIChoice]
}

private struct AIChoice: Decodable {
    let message: AIMessageResponse
}

private struct AIMessageResponse: Decodable {
    let content: String
}
