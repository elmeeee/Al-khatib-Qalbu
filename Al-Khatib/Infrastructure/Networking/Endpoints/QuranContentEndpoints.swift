//
//  QuranContentEndpoints.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum QuranContentEndpoint: QFEndpoint {
    case chapters(query: [URLQueryItem])
    case versesByChapter(chapterNumber: Int, query: [URLQueryItem])
    case randomAyah(query: [URLQueryItem])
    case resourcesRecitations(query: [URLQueryItem])
    case resourcesTranslations(query: [URLQueryItem])
    case tafsirByAyah(resourceId: String, ayahKey: String, query: [URLQueryItem])
    case hadithsByAyah(ayahKey: String, query: [URLQueryItem])
    case verseByKey(verseKey: String, query: [URLQueryItem])

    var route: QFApiClient.RequestRoute { .content }
    var method: QFHTTPMethod { .get }

    var path: String {
        switch self {
        case .chapters:
            return AppEndpoints.Content.chapters
        case .versesByChapter(let chapterNumber, _):
            return AppEndpoints.Content.versesByChapter(chapterNumber)
        case .randomAyah:
            return AppEndpoints.Content.versesRandom
        case .resourcesRecitations:
            return AppEndpoints.Content.resourcesRecitations
        case .resourcesTranslations:
            return AppEndpoints.Content.resourcesTranslations
        case .tafsirByAyah(let resourceId, let ayahKey, _):
            return AppEndpoints.Content.tafsirByAyah(resourceId: resourceId, ayahKey: ayahKey)
        case .hadithsByAyah(let ayahKey, _):
            return AppEndpoints.Content.hadithsByAyah(ayahKey)
        case .verseByKey(let verseKey, _):
            return AppEndpoints.Content.verseByKey(verseKey)
        }
    }

    var query: [URLQueryItem] {
        switch self {
        case .chapters(let query),
             .versesByChapter(_, let query),
             .randomAyah(let query),
             .resourcesRecitations(let query),
             .resourcesTranslations(let query),
             .tafsirByAyah(_, _, let query),
             .hadithsByAyah(_, let query),
             .verseByKey(_, let query):
            return query
        }
    }

    var bodyData: Data? { nil }
}
