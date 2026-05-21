//
//  VerseSheetItem.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct VerseSheetItem: Identifiable {
    let id: String
    init(verseKey: String) { self.id = verseKey }
}
