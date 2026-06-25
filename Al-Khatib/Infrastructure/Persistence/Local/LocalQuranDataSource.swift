//
//  LocalQuranDataSource.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

internal final class LocalQuranDataSource: Sendable {
    private let database: LocalQuranDatabase
    private let tafsirCache = TafsirJsonCache.shared

    private static let AYAH_SELECT = """
        a.sura, a.aya, a.text, a.indonesian, a.malay, a.translation_en, a.kemenag,
        a.jalalayn, a.transliteration_id, a.transliteration_en,
        a.page, a.juz, a."index", CAST(s.start AS INTEGER) + a.aya AS global_ayah
    """

    internal init(database: LocalQuranDatabase = .shared) {
        self.database = database
    }

    internal func getChapters(language: String = "en") async throws -> [QuranChapter] {
        let db = try database.openReadable()
        defer { db.close() }

        let query = """
            SELECT "index", tname, ename, ename_english, ayas, type, first_page, last_page, name
            FROM suras
            ORDER BY "index"
        """

        let rows = try db.execute(query: query)
        return rows.map { row in
            let index = row["index"] as? Int ?? 0
            let tname = row["tname"] as? String ?? ""
            let enameId = row["ename"] as? String ?? ""
            let enameEnglish = row["ename_english"] as? String ?? ""
            let ayas = row["ayas"] as? Int ?? 0
            let type = row["type"] as? String ?? ""
            let firstPage = row["first_page"] as? Int ?? 1
            let lastPage = row["last_page"] as? Int ?? firstPage
            let nameArabic = row["name"] as? String

            let meaning = (language == "en") ?
                (!enameEnglish.isEmpty ? enameEnglish : enameId) :
                (!enameId.isEmpty ? enameId : enameEnglish)

            let meaningLang = (language == "en") ? "english" : "indonesian"

            let revelation = ["mekkah", "mecca", "makkah"].contains(type.lowercased()) ? "makkah" :
                             (["madinah", "medina"].contains(type.lowercased()) ? "madinah" : type.lowercased())

            return QuranChapter(
                id: index,
                revelationPlace: revelation,
                revelationOrder: nil,
                bismillahPre: nil,
                pages: Array(firstPage...lastPage),
                nameSimple: tname,
                nameComplex: tname,
                nameArabic: nameArabic,
                versesCount: ayas,
                translatedName: ChapterTranslatedName(languageName: meaningLang, name: meaning)
            )
        }
    }

    internal func getJuzs() async throws -> [QuranJuz] {
        var list: [QuranJuz] = []
        for i in 1...30 {
            if let juz = try await getJuz(juzNumber: i) {
                list.append(juz)
            }
        }
        return list
    }

    internal func getJuz(juzNumber: Int) async throws -> QuranJuz? {
        guard (1...30).contains(juzNumber) else { return nil }
        let db = try database.openReadable()
        defer { db.close() }

        let query = """
            SELECT sura, MIN(aya) AS min_aya, MAX(aya) AS max_aya, COUNT(*) AS cnt
            FROM ayas
            WHERE juz = ?
            GROUP BY sura
            ORDER BY sura
        """

        let rows = try db.execute(query: query, params: [String(juzNumber)])
        guard !rows.isEmpty else { return nil }

        var mapping: [String: String] = [:]
        var total = 0
        for row in rows {
            let sura = row["sura"] as? Int ?? 0
            let minAya = row["min_aya"] as? Int ?? 0
            let maxAya = row["max_aya"] as? Int ?? 0
            let cnt = row["cnt"] as? Int ?? 0
            total += cnt
            mapping[String(sura)] = (minAya == maxAya) ? String(minAya) : "\(minAya)-\(maxAya)"
        }

        return QuranJuz(
            id: juzNumber,
            juzNumber: juzNumber,
            verseMapping: mapping,
            versesCount: total
        )
    }

    internal func getVersesByChapter(
        chapterNumber: Int,
        page: Int,
        perPage: Int,
        translationId: Int,
        recitationId: Int
    ) async throws -> VersesByChapterResponse {
        let db = try database.openReadable()
        defer { db.close() }

        let total = db.intQuery(query: "SELECT COUNT(*) FROM ayas WHERE sura = ?", params: [String(chapterNumber)])
        let offset = max(0, page - 1) * perPage

        let query = """
            SELECT \(Self.AYAH_SELECT)
            FROM ayas a
            JOIN suras s ON s."index" = a.sura
            WHERE a.sura = ?
            ORDER BY a.aya
            LIMIT ? OFFSET ?
        """

        let rows = try db.execute(query: query, params: [String(chapterNumber), String(perPage), String(offset)])
        let verses = rows.map { row in
            self.toVersePayload(row, translationId: translationId, recitationId: recitationId)
        }

        return paginatedResponse(verses, page: page, perPage: perPage, total: total)
    }

    internal func getVersesByJuz(
        juzNumber: Int,
        page: Int,
        perPage: Int,
        translationId: Int,
        recitationId: Int
    ) async throws -> VersesByChapterResponse {
        let db = try database.openReadable()
        defer { db.close() }

        let total = db.intQuery(query: "SELECT COUNT(*) FROM ayas WHERE juz = ?", params: [String(juzNumber)])
        let offset = max(0, page - 1) * perPage

        let query = """
            SELECT \(Self.AYAH_SELECT)
            FROM ayas a
            JOIN suras s ON s."index" = a.sura
            WHERE a.juz = ?
            ORDER BY a."index"
            LIMIT ? OFFSET ?
        """

        let rows = try db.execute(query: query, params: [String(juzNumber), String(perPage), String(offset)])
        let verses = rows.map { row in
            self.toVersePayload(row, translationId: translationId, recitationId: recitationId)
        }

        return paginatedResponse(verses, page: page, perPage: perPage, total: total)
    }

    internal func getVersesByMushafPage(
        mushafPage: Int,
        translationId: Int,
        recitationId: Int
    ) async throws -> VersesByChapterResponse {
        let db = try database.openReadable()
        defer { db.close() }

        let query = """
            SELECT DISTINCT \(Self.AYAH_SELECT)
            FROM ayas a
            JOIN suras s ON s."index" = a.sura
            WHERE a.page = ?
            ORDER BY a."index"
        """

        let rows = try db.execute(query: query, params: [String(mushafPage)])
        let verses = rows.map { row in
            self.toVersePayload(row, translationId: translationId, recitationId: recitationId)
        }

        return VersesByChapterResponse(verses: verses, pagination: nil)
    }

    internal func getRandomAyah(translationId: Int, recitationId: Int) async throws -> RandomAyahPayload? {
        let total = try await totalAyahCount()
        guard total > 0 else { return nil }
        let offset = Int.random(in: 0..<total)
        return try await loadAyahAtOffset(offset, translationId: translationId, recitationId: recitationId)
    }

    internal func getDailyAyah(translationId: Int, recitationId: Int) async throws -> RandomAyahPayload? {
        let total = try await totalAyahCount()
        guard total > 0 else { return nil }
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let offset = (dayOfYear - 1) % total
        return try await loadAyahAtOffset(offset, translationId: translationId, recitationId: recitationId)
    }

    private func totalAyahCount() async throws -> Int {
        let db = try database.openReadable()
        defer { db.close() }
        return db.intQuery(query: "SELECT COUNT(*) FROM ayas")
    }

    private func loadAyahAtOffset(_ offset: Int, translationId: Int, recitationId: Int) async throws -> RandomAyahPayload? {
        let db = try database.openReadable()
        defer { db.close() }

        let query = """
            SELECT \(Self.AYAH_SELECT)
            FROM ayas a
            JOIN suras s ON s."index" = a.sura
            ORDER BY a."index"
            LIMIT 1 OFFSET ?
        """

        let rows = try db.execute(query: query, params: [String(offset)])
        guard let first = rows.first else { return nil }
        return toVersePayload(first, translationId: translationId, recitationId: recitationId)
    }

    internal func getVerseByKey(_ verseKey: String, translationId: Int, recitationId: Int) async throws -> RandomAyahPayload? {
        let parts = verseKey.split(separator: ":")
        guard parts.count == 2,
              let sura = Int(parts[0]),
              let aya = Int(parts[1]) else { return nil }

        let db = try database.openReadable()
        defer { db.close() }

        let query = """
            SELECT \(Self.AYAH_SELECT)
            FROM ayas a
            JOIN suras s ON s."index" = a.sura
            WHERE a.sura = ? AND a.aya = ?
        """

        let rows = try db.execute(query: query, params: [String(sura), String(aya)])
        guard let first = rows.first else { return nil }
        return toVersePayload(first, translationId: translationId, recitationId: recitationId)
    }

    internal func mushafPageForVerse(chapterNumber: Int, verseNumber: Int) async throws -> Int? {
        let db = try database.openReadable()
        defer { db.close() }
        return db.intQueryOrNull(query: "SELECT page FROM ayas WHERE sura = ? AND aya = ?", params: [String(chapterNumber), String(verseNumber)])
    }

    internal func firstMushafPageForChapter(_ chapterNumber: Int) async throws -> Int? {
        let db = try database.openReadable()
        defer { db.close() }
        return db.intQueryOrNull(query: "SELECT MIN(page) FROM ayas WHERE sura = ?", params: [String(chapterNumber)])
    }

    internal func firstMushafPageForJuz(_ juzNumber: Int) async throws -> Int? {
        let db = try database.openReadable()
        defer { db.close() }

        let query = "SELECT sura, aya FROM juzs WHERE \"index\" = ?"
        let rows = try db.execute(query: query, params: [String(juzNumber)])
        guard let first = rows.first,
              let sura = first["sura"] as? Int,
              let aya = first["aya"] as? Int else { return nil }

        return db.intQueryOrNull(
            query: "SELECT page FROM ayas WHERE sura = ? AND aya = ?",
            params: [String(sura), String(aya)]
        )
    }

    internal func getPagesLookup(
        chapterNumber: Int? = nil,
        juzNumber: Int? = nil,
        pageNumber: Int? = nil,
        fromVerse: String? = nil,
        toVerse: String? = nil
    ) async throws -> PagesLookupResponse {
        var page = pageNumber
        if page == nil, let fromVerse = fromVerse {
            page = try await mushafPageForVerseKey(fromVerse)
        }
        if page == nil, let chapterNumber = chapterNumber {
            page = try await firstMushafPageForChapter(chapterNumber)
        }
        if page == nil, let juzNumber = juzNumber {
            page = try await firstMushafPageForJuz(juzNumber)
        }

        guard let resolvedPage = page else {
            return PagesLookupResponse(lookupRange: LookupRange(from: "", to: ""), pages: [:], totalPage: 604)
        }

        let db = try database.openReadable()
        defer { db.close() }

        let first = db.stringQuery(
            query: "SELECT sura || ':' || aya FROM ayas WHERE page = ? ORDER BY \"index\" LIMIT 1",
            params: [String(resolvedPage)]
        ) ?? ""

        let last = db.stringQuery(
            query: "SELECT sura || ':' || aya FROM ayas WHERE page = ? ORDER BY \"index\" DESC LIMIT 1",
            params: [String(resolvedPage)]
        ) ?? first

        let lookup = LookupRange(from: first, to: last)
        let pageInfo = PageInfo(from: first, to: last)

        return PagesLookupResponse(
            lookupRange: lookup,
            pages: [String(resolvedPage): pageInfo],
            totalPage: 604
        )
    }

    private func mushafPageForVerseKey(_ key: String) async throws -> Int? {
        let parts = key.split(separator: ":")
        guard parts.count == 2,
              let sura = Int(parts[0]),
              let aya = Int(parts[1]) else { return nil }
        return try await mushafPageForVerse(chapterNumber: sura, verseNumber: aya)
    }

    internal func getTafsirByAyah(ayahKey: String, resourceId: String) async throws -> TafsirPayload? {
        let parts = ayahKey.split(separator: ":")
        guard parts.count == 2,
              let sura = Int(parts[0]),
              let aya = Int(parts[1]) else { return nil }

        if resourceId == "jalalayn" {
            let db = try database.openReadable()
            defer { db.close() }
            if let jalalayn = db.stringQuery(
                query: "SELECT jalalayn FROM ayas WHERE sura = ? AND aya = ?",
                params: [String(sura), String(aya)]
            ), !jalalayn.isEmpty {
                return TafsirPayload(id: sura * 1000 + aya, text: jalalayn, resourceId: 0, resourceName: "Tafsir Jalalayn")
            }
            return nil
        }

        let db = try database.openReadable()
        defer { db.close() }
        if let idx = db.intQueryOrNull(
            query: "SELECT \"index\" FROM ayas WHERE sura = ? AND aya = ?",
            params: [String(sura), String(aya)]
        ) {
            let texts = await tafsirCache.tafsirTexts()
            if idx > 0 && idx <= texts.count {
                let text = texts[idx - 1]
                if !text.isEmpty {
                    return TafsirPayload(id: idx, text: text, resourceId: 0, resourceName: "Tafsir Indonesia (lokal)")
                }
            }
        }
        return nil
    }

    internal func searchVerses(query: String, translationId: Int, limit: Int = 10) async throws -> [RandomAyahPayload] {
        let column = translationColumn(translationId)
        let db = try database.openReadable()
        defer { db.close() }

        let sql = """
            SELECT \(Self.AYAH_SELECT)
            FROM ayas a
            JOIN suras s ON s."index" = a.sura
            WHERE \(column) LIKE ?
            ORDER BY a."index"
            LIMIT ?
        """

        let rows = try db.execute(query: sql, params: ["%\(query)%", String(limit)])
        return rows.map { row in
            toVersePayload(row, translationId: translationId, recitationId: 6)
        }
    }

    private func toVersePayload(_ row: [String: Any], translationId: Int, recitationId: Int) -> RandomAyahPayload {
        let sura = row["sura"] as? Int ?? 0
        let aya = row["aya"] as? Int ?? 0
        let globalAyah = row["global_ayah"] as? Int ?? 0
        let page = row["page"] as? Int ?? 1
        let juz = row["juz"] as? Int ?? 1

        let text = row["text"] as? String ?? ""

        // Map audio
        // In local, we calculate local URL or remote fallback URL
        let audioUrl = localMurottalUrl(recitationId: recitationId, globalAyah: globalAyah, sura: sura, aya: aya)

        // Map translation
        var translationText = ""
        switch translationId {
        case 131: // English
            translationText = row["translation_en"] as? String ?? ""
        case 39: // Malay
            translationText = row["malay"] as? String ?? ""
        case 33: // Kemenag
            translationText = row["kemenag"] as? String ?? ""
        default: // Indonesian (33)
            translationText = row["indonesian"] as? String ?? ""
        }

        let inlineTranslation = InlineTranslation(
            id: translationId,
            resourceId: translationId,
            text: translationText,
            resourceName: translationResourceName(translationId)
        )

        return RandomAyahPayload(
            id: row["index"] as? Int,
            verseNumber: aya,
            verseKey: "\(sura):\(aya)",
            textIndopak: nil,
            textImlaeiSimple: nil,
            textImlaei: nil,
            textUthmani: text,
            textUthmaniSimple: nil,
            textUthmaniTajweed: text, // local db "text" is clean uthmani
            textQpcHafs: nil,
            textQpcNastaleeqHafs: nil,
            textQpcNastaleeq: nil,
            textIndopakNastaleeq: nil,
            pageNumber: page,
            juzNumber: juz,
            audio: AudioPayload(url: audioUrl),
            translations: [inlineTranslation]
        )
    }

    private func localMurottalUrl(recitationId: Int, globalAyah: Int, sura: Int, aya: Int) -> String {
        // Fallback or local checked.
        // Android does: LocalQuranConfig.murottalUrl(recitationId, globalAyah)
        // Let's generate the default remote one:
        // https://everyayah.com/data/<recitation_path>/<3-digit surah><3-digit ayah>.mp3 or similar
        // Let's check what URL Android generates:
        let reciterMap: [Int: String] = [
            1: "Abdul_Basit_Murattal_64kbps",
            2: "Abdul_Basit_Mujawwad_128kbps",
            3: "Abdurrahim_As-Sudais_128kbps",
            4: "Abu_Bakr_Ash-Shaatree_128kbps",
            5: "Al-Ghamadi_40kbps",
            6: "Alafasy_128kbps",
            7: "Hani_Rifai_192kbps",
            8: "Husary_64kbps",
            9: "Hudhaify_64kbps",
            10: "Maher_AlMuaiqly_64kbps"
        ]
        let reciter = reciterMap[recitationId] ?? "Alafasy_128kbps"
        let file = String(format: "%03d%03d.mp3", sura, aya)
        return "https://everyayah.com/data/\(reciter)/\(file)"
    }

    private func recitationSubpath(_ id: Int) -> String {
        return "Alafasy_128kbps"
    }

    private func translationResourceName(_ id: Int) -> String {
        switch id {
        case 131: return "English"
        case 39: return "Malay"
        case 33: return "Kemenag"
        default: return "Indonesian"
        }
    }

    private func translationColumn(_ id: Int) -> String {
        switch id {
        case 131: return "a.translation_en"
        case 39: return "a.malay"
        case 33: return "a.kemenag"
        default: return "a.indonesian"
        }
    }

    private func paginatedResponse(
        _ verses: [RandomAyahPayload],
        page: Int,
        perPage: Int,
        total: Int
    ) -> VersesByChapterResponse {
        let totalPages = total == 0 ? 0 : ((total + perPage - 1) / perPage)
        let nextPage = page < totalPages ? page + 1 : nil
        let pagination = ContentPagination(
            perPage: perPage,
            currentPage: page,
            nextPage: nextPage,
            totalPages: totalPages,
            totalRecords: total
        )
        return VersesByChapterResponse(verses: verses, pagination: pagination)
    }

    internal func getVersesByRange(
        chapterNumber: Int,
        startAyah: Int,
        endAyah: Int,
        translationId: Int
    ) async throws -> [RandomAyahPayload] {
        let db = try database.openReadable()
        defer { db.close() }

        let query = """
            SELECT \(Self.AYAH_SELECT)
            FROM ayas a
            JOIN suras s ON s."index" = a.sura
            WHERE a.sura = ? AND a.aya >= ? AND a.aya <= ?
            ORDER BY a.aya
        """

        let rows = try db.execute(
            query: query,
            params: [String(chapterNumber), String(startAyah), String(endAyah)]
        )
        return rows.map { row in
            self.toVersePayload(row, translationId: translationId, recitationId: 6)
        }
    }
}

// Simple Cache Actor for Tafsir JSON
private actor TafsirJsonCache {
    internal static let shared = TafsirJsonCache()

    private var cachedTexts: [String]?

    internal func tafsirTexts() -> [String] {
        if let cached = cachedTexts { return cached }
        guard let path = Bundle.main.path(forResource: "tafsir", ofType: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let texts = try JSONDecoder().decode([String].self, from: data)
            cachedTexts = texts
            return texts
        } catch {
            print("Failed to decode tafsir.json: \(error.localizedDescription)")
            return []
        }
    }
}
