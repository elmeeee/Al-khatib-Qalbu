//
//  ChapterCatalog.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

@MainActor
enum ChapterCatalog {
    private static var namesByChapterId: [Int: String] = [:]

    static func register(_ chapters: [QuranChapter]) {
        guard chapters.isEmpty == false else { return }
        for chapter in chapters {
            let name = chapter.displayComplexName
            guard name.isEmpty == false else { continue }
            namesByChapterId[chapter.id] = name
        }
    }

    static func displayName(forChapterId id: Int) -> String? {
        namesByChapterId[id]
    }

    static func clear() {
        namesByChapterId.removeAll()
    }
}
