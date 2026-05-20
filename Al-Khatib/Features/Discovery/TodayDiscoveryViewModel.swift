//
//  SemanticDiscoveryViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//


import Foundation
import Observation
import AVFoundation

@MainActor
@Observable
final class TodayDiscoveryViewModel {
    var errorMessage: String?
    var activeAudioURL: String?
    var detail: RandomAyahPayload?
    var isDetailLoading = false
    var isTranslationLoading = false
    var isTafsirLoading = false
    var isRecitationLoading = false
    var recitations: [RecitationPayload] = []
    var selectedRecitationId: Int = 6
    private var audioPlayer: AVPlayer?
    var isPlayingAudio = false

    private let content: QuranContentRepository
    private let defaults = UserDefaults.standard
    private let randomAyahLastFetchKey = "discover.randomAyah.lastFetchAt"
    private let randomAyahRefreshInterval: TimeInterval = 60 * 60
    private var shareTextCache: [String: String] = [:]
    private var shareTafsirCache: [String: String] = [:]

    init(content: QuranContentRepository) {
        self.content = content
    }

    private static func deviceLanguageCode() -> String {
        let preferred = Locale.preferredLanguages.first ?? Locale.current.identifier
        let locale = Locale(identifier: preferred)
        if #available(iOS 16.0, *) {
            if let code = locale.language.languageCode?.identifier, code.isEmpty == false {
                return code
            }
        } else {
            let code = locale.languageCode ?? ""
            if code.isEmpty == false { return code }
        }
        let fallback = preferred.split(separator: "-").first.map(String.init) ?? "en"
        return fallback
    }

    func loadDailyAyahWithHadith() {
        stopAudio()
        detail = nil
        isDetailLoading = true
        errorMessage = nil
        Task {
            do {
                async let ayahTask = content.getRandomAyah()
                async let recitationsTask: [RecitationPayload]? = recitations.isEmpty
                    ? (try? content.getRecitations().recitations)
                    : nil

                let response = try await ayahTask
                guard let verse = response.verse else {
                    throw QFError.parsingError("daily verse payload")
                }

                self.detail = .init(verse)
                self.defaults.set(Date().timeIntervalSince1970, forKey: self.randomAyahLastFetchKey)

                if let fetched = await recitationsTask, fetched.isEmpty == false {
                    self.recitations = fetched
                }
            } catch {
                self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            self.isDetailLoading = false
        }
    }

    func autoRefreshDailyAyahIfNeeded(forceIfNoData: Bool = true) {
        guard isDetailLoading == false else { return }
        if shouldRefreshRandomAyah(forceIfNoData: forceIfNoData) {
            loadDailyAyahWithHadith()
        }
    }

    private func shouldRefreshRandomAyah(forceIfNoData: Bool) -> Bool {
        if forceIfNoData, detail == nil {
            return true
        }
        let last = defaults.double(forKey: randomAyahLastFetchKey)
        if last <= 0 { return true }
        let elapsed = Date().timeIntervalSince1970 - last
        return elapsed >= randomAyahRefreshInterval
    }
    
    func toggleAudio(urlStr: String?) {
        guard let urlStr = urlStr else { return }
        let finalURLStr = AppEndpoints.URLBuilder.absoluteVerseMediaURLString(from: urlStr)
        guard let finalURL = URL(string: finalURLStr) else { return }

        if let player = audioPlayer, isPlayingAudio {
            player.pause()
            isPlayingAudio = false
        } else {
            if audioPlayer == nil {
                let item = AVPlayerItem(url: finalURL)
                audioPlayer = AVPlayer(playerItem: item)
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: item,
                    queue: .main
                ) { [weak self] _ in
                    guard let self else { return }
                    Task { @MainActor in
                        self.isPlayingAudio = false
                        self.audioPlayer?.seek(to: .zero)
                    }
                }
            }
            audioPlayer?.play()
            isPlayingAudio = true
        }
    }
    
    func stopAudio() {
        audioPlayer?.pause()
        audioPlayer = nil
        isPlayingAudio = false
    }

    func prefetchShareTextIfNeeded(for verse: RandomAyahPayload) async {
        guard let cacheKey = shareCacheKey(for: verse) else { return }
        guard shareTextCache[cacheKey] == nil else { return }
        let text = await prepareShareText(for: verse)
        shareTextCache[cacheKey] = text
    }

    func cachedShareText(for verse: RandomAyahPayload) -> String? {
        guard let cacheKey = shareCacheKey(for: verse),
              let cached = shareTextCache[cacheKey] else {
            return nil
        }
        let trimmed = cached.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func quickReflectionText(for verse: RandomAyahPayload) -> String {
        let verseKey = resolvedAyahKey(for: verse) ?? verse.verseKey
        let arabic = verse.displayText ?? ""
        let translation = verse.translations?.first?.text
        let tafsir: String? = {
            guard let verseKey else { return nil }
            let cached = shareTafsirCache[verseKey] ?? ""
            return cached.isEmpty ? nil : cached
        }()
        return guaranteedFaithfulShareText(
            verseKey: verseKey,
            arabic: arabic,
            translation: translation,
            tafsir: tafsir
        )
    }

    func prepareShareText(for verse: RandomAyahPayload) async -> String {
        let cacheKey = shareCacheKey(for: verse)
        if let cacheKey, let cached = shareTextCache[cacheKey], cached.isEmpty == false {
            return cached
        }

        let verseKey = resolvedAyahKey(for: verse) ?? verse.verseKey
        let arabic = verse.displayText ?? ""
        let translation = verse.translations?.first?.text
        let tafsir = await loadTafsirForShare(ayahKey: verseKey)

        let reflection = await generatePersonalizedReflection(
            verseKey: verseKey,
            arabic: arabic,
            translation: translation,
            tafsir: tafsir,
            verseNumber: verse.verseNumber,
            juzNumber: verse.juzNumber,
            pageNumber: verse.pageNumber,
            translationSource: verse.translations?.first?.resourceName,
            translationResourceId: verse.translations?.first?.resourceId,
            verseRecordId: verse.id
        )

        let final = buildFaithfulShareText(
            verseKey: verseKey,
            arabic: arabic,
            translation: translation,
            tafsir: tafsir,
            aiReflection: reflection
        ) ?? guaranteedFaithfulShareText(
            verseKey: verseKey,
            arabic: arabic,
            translation: translation,
            tafsir: tafsir
        )

        if let cacheKey {
            shareTextCache[cacheKey] = final
        }
        return final
    }

    private func loadTafsirForShare(ayahKey: String?) async -> String? {
        guard let ayahKey, ayahKey.isEmpty == false else { return nil }
        if let cached = shareTafsirCache[ayahKey] {
            return cached.isEmpty ? nil : cached
        }
        return await withTaskGroup(of: String?.self) { group in
            group.addTask { [content] in
                if let response = try? await content.getTafsirByAyah(resourceId: "169", ayahKey: ayahKey) {
                    return response.tafsir?.textStrippingHTML?.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return nil
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                return nil
            }
            let value = await group.next() ?? nil
            group.cancelAll()
            if let value {
                self.shareTafsirCache[ayahKey] = value
            } else {
                self.shareTafsirCache[ayahKey] = ""
            }
            return value
        }
    }

    private func resolvedAyahKey(for verse: RandomAyahPayload) -> String? {
        guard let key = verse.verseKey, key.isEmpty == false else { return nil }
        return key
    }

    private func shareCacheKey(for verse: RandomAyahPayload) -> String? {
        if let key = resolvedAyahKey(for: verse) { return key }
        if let id = verse.id { return "id-\(id)" }
        return nil
    }

    private func buildFaithfulShareText(
        verseKey: String?,
        arabic: String?,
        translation: String?,
        tafsir: String?,
        aiReflection: String?
    ) -> String? {
        let cleanedTranslation = translation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cleanedArabic = arabic?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let verseLabel = verseKey.map(ShareVerseCard.humanLabel(for:)) ?? "Quran"

        let verseBlock: String = {
            if cleanedTranslation.isEmpty == false {
                return "📖 _\"\(cleanedTranslation)\"_\n(\(verseLabel))"
            }
            if cleanedArabic.isEmpty == false {
                return "📖 _\(cleanedArabic)_\n(\(verseLabel))"
            }
            return "📖 (\(verseLabel))"
        }()

        let reflection = aiReflection?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let reflection, reflection.isEmpty == false else { return nil }
        guard isReflectionAligned(reflection, translation: cleanedTranslation, tafsir: tafsir) else { return nil }
        let now = Date()
        let addressLine = dynamicAddressLine(now: now)
        let transitionLine = dynamicTransitionLine(now: now)

        return """
        *Al-Khatib | Quran Foundation*
        _1 Verse, 1 Day 📖 Read, Reflect, Share_

        \(addressLine)
        \(transitionLine)

        *Allah s.w.t says:*
        \(verseBlock)

        \(reflection)

        🤲 *Ya Allah,*
        purify our hearts and our tongues. Guide us to truth, protect us from assumptions, and grant us wisdom before words.

        \(hashtagsBlock())
        """
    }

    private func generatePersonalizedReflection(
        verseKey: String?,
        arabic: String?,
        translation: String?,
        tafsir: String?,
        verseNumber: Int?,
        juzNumber: Int?,
        pageNumber: Int?,
        translationSource: String?,
        translationResourceId: Int?,
        verseRecordId: Int?
    ) async -> String? {
        let apiKey = TodayDiscoveryViewModel.groqAPIKey()
        guard apiKey.isEmpty == false else { return nil }

        let verseLabel = verseKey.map(ShareVerseCard.humanLabel(for:)) ?? "Quran verse"
        let translationText = translation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let arabicText = arabic?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let tafsirText = (tafsir ?? "").replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceName = translationSource?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let verseNumberLabel = verseNumber.map(String.init) ?? "N/A"
        let juzLabel = juzNumber.map(String.init) ?? "N/A"
        let pageLabel = pageNumber.map(String.init) ?? "N/A"
        let translationResourceLabel = translationResourceId.map(String.init) ?? "N/A"
        let verseRecordLabel = verseRecordId.map(String.init) ?? "N/A"

        let system = """
        You write concise Islamic reflections for social sharing.
        Return plain text only (no JSON, no markdown code fences).
        Keep aqidah-safe and avoid inventing hadith references.
        Stay faithful to the provided verse and tafsir context.
        """
        let user = """
        Write only the REFLECTION section (4-6 short lines).
        Do not include title, verse quote, reference, dua, or hashtags.
        Focus on practical heart-check and behavior.

        Constraints:
        - Language: English.
        - Warm, reflective, gentle tone.
        - Keep under 70 words.
        - Do not introduce new facts, stories, or claims outside the given verse + tafsir.
        - Please cite hadith.
        - Use this verse reference: \(verseLabel)
        - Verse number: \(verseNumberLabel)
        - Juz number: \(juzLabel)
        - Page number: \(pageLabel)
        - Internal verse record id: \(verseRecordLabel)
        - Translation (primary source): \(translationText.isEmpty ? "N/A" : translationText)
        - Translation source name: \(sourceName.isEmpty ? "N/A" : sourceName)
        - Translation resource id: \(translationResourceLabel)
        - Arabic text (optional): \(arabicText.isEmpty ? "N/A" : arabicText)
        - Tafsir context (for meaning only, do not quote if empty): \(tafsirText.isEmpty ? "N/A" : String(tafsirText.prefix(1200)))
        """

        let body = GroqChatRequest(
            model: TodayDiscoveryViewModel.groqModel(),
            messages: [
                .init(role: "system", content: system),
                .init(role: "user", content: user)
            ],
            temperature: 0.35
        )

        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions"),
              let data = try? JSONEncoder().encode(body) else { return nil }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = data
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (respData, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            let decoded = try JSONDecoder().decode(GroqChatResponse.self, from: respData)
            let raw = decoded.choices.first?.message.content ?? ""
            let content = sanitizeModelOutput(raw).trimmingCharacters(in: .whitespacesAndNewlines)
            return content.isEmpty ? nil : content
        } catch {
            return nil
        }
    }

    private func guaranteedFaithfulShareText(
        verseKey: String?,
        arabic: String?,
        translation: String?,
        tafsir: String?
    ) -> String {
        let verseLabel = verseKey.map(ShareVerseCard.humanLabel(for:)) ?? "Quran"
        let cleanedTranslation = translation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cleanedArabic = arabic?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let tafsirLine = tafsir?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let verseBlock: String = {
            if cleanedTranslation.isEmpty == false {
                return "📖 _\"\(cleanedTranslation)\"_\n(\(verseLabel))"
            }
            if cleanedArabic.isEmpty == false {
                return "📖 _\(cleanedArabic)_\n(\(verseLabel))"
            }
            return "📖 (\(verseLabel))"
        }()
        let tafsirSummary: String = {
            guard tafsirLine.isEmpty == false else {
                return "Take this verse as a direct reminder to verify before reacting and to guard your tongue with truth."
            }
            return String(tafsirLine.prefix(220))
        }()

        return """
        *Al-Khatib | Quran Foundation*
        _1 Verse, 1 Day 📖 Read, Reflect, Share_

        _My friend..._
        Let this verse guide what you believe, what you repeat, and what you carry in your heart.

        *Allah s.w.t says:*
        \(verseBlock)

        Reflection:
        \(tafsirSummary)

        🤲 *Ya Allah,*
        purify our hearts and our tongues. Guide us to truth, protect us from assumptions, and grant us wisdom before words.

        \(hashtagsBlock())
        """
    }

    private func dynamicAddressLine(now: Date) -> String {
        let period = shareDayPeriod(now: now)
        let options: [String]
        switch period {
        case .morning:
            options = ["_My brother this morning..._", "_My sister this morning..._", "_Dear soul this morning..._"]
        case .afternoon:
            options = ["_My friend this afternoon..._", "_Dear heart this afternoon..._", "_Beloved seeker this afternoon..._"]
        case .evening:
            options = ["_My friend this evening..._", "_Dear soul this evening..._", "_My brother this evening..._"]
        case .night:
            options = ["_Dear heart tonight..._", "_My friend tonight..._", "_Beloved seeker tonight..._"]
        }
        return options.randomElement() ?? "_My friend..._"
    }

    private func dynamicTransitionLine(now: Date) -> String {
        "\(dayAwareHook(now: now)) \(periodAwareReminder(now: now))"
    }

    private func dayAwareHook(now: Date) -> String {
        switch Calendar.current.component(.weekday, from: now) {
        case 2: return "*As a new week begins,*"
        case 3: return "*As this Tuesday moves on,*"
        case 4: return "*Midweek reminder,*"
        case 5: return "*As Thursday passes,*"
        case 6: return "*As Jumu'ah approaches,*"
        case 7: return "*This weekend,*"
        default: return "*On this Sunday,*"
        }
    }

    private func periodAwareReminder(now: Date) -> String {
        let reminders: [String]
        switch shareDayPeriod(now: now) {
        case .morning:
            reminders = [
                "start your day with clarity before you absorb every voice around you.",
                "set your intention early: verify before believing, and reflect before reacting.",
                "let this verse anchor your mind before the rush begins."
            ]
        case .afternoon:
            reminders = [
                "pause in the middle of your day and realign your heart with what is true.",
                "protect your peace by filtering what you hear and what you repeat.",
                "let this verse interrupt assumptions and restore clarity."
            ]
        case .evening:
            reminders = [
                "before the day closes, return your heart to truth and humility.",
                "slow down tonight and release conclusions you built without certainty.",
                "let this verse cleanse today's noise before it enters your heart."
            ]
        case .night:
            reminders = [
                "before you rest, leave rumours behind and hold on to what is clear.",
                "close your night with reflection, not assumptions.",
                "let this verse be your final filter before sleep."
            ]
        }
        return reminders.randomElement() ?? "let this verse guide your heart before your reaction."
    }

    private func hashtagsBlock() -> String {
        let daySpecific: String
        switch Calendar.current.component(.weekday, from: Date()) {
        case 2: daySpecific = "#MondayMotivation 🌅"
        case 3: daySpecific = "#TuesdayTadabbur 🌿"
        case 4: daySpecific = "#WednesdayWisdom ✨"
        case 5: daySpecific = "#ThursdayReflection 📚"
        case 6: daySpecific = "#JumuahReminder 🌙"
        case 7: daySpecific = "#SaturdayReflection 🍃"
        default: daySpecific = "#SundaySerenity ☁️"
        }
        return """
        #QuranReminder 🌿
        #ReadReflectShare 🤍
        \(daySpecific)
        """
    }

    private func isReflectionAligned(_ reflection: String, translation: String, tafsir: String?) -> Bool {
        let source = "\(translation) \(tafsir ?? "")".lowercased()
        if source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        let reflectionLower = reflection.lowercased()
        let sourceWords = Set(
            source
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 5 }
        )
        if sourceWords.isEmpty { return true }
        return sourceWords.contains { reflectionLower.contains($0) }
    }

    private func sanitizeModelOutput(_ raw: String) -> String {
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

    private static func groqAPIKey() -> String {
        Bundle.main.infoDictionary?["API_KEY_GROQ"] as? String ?? ""
    }
    
    private static func groqModel() -> String {
        Bundle.main.infoDictionary?["AI_MODEL"] as? String ?? ""
    }

    private enum ShareDayPeriod {
        case morning, afternoon, evening, night
    }

    private func shareDayPeriod(now: Date) -> ShareDayPeriod {
        switch Calendar.current.component(.hour, from: now) {
        case 5..<12: return .morning
        case 12..<16: return .afternoon
        case 16..<20: return .evening
        default: return .night
        }
    }
}

private struct GroqChatRequest: Encodable {
    let model: String
    let messages: [GroqMessage]
    let temperature: Double
}

private struct GroqMessage: Encodable {
    let role: String
    let content: String
}

private struct GroqChatResponse: Decodable {
    let choices: [GroqChoice]
}

private struct GroqChoice: Decodable {
    let message: GroqMessageResponse
}

private struct GroqMessageResponse: Decodable {
    let content: String
}
