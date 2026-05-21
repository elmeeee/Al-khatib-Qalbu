//
//  MappedPrayerItem.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct MappedPrayerItem: Identifiable, Equatable, Sendable {
    let id: String
    let originalName: String
    let displayName: String
    let timeString: String
    let date: Date
    let isActive: Bool
}
