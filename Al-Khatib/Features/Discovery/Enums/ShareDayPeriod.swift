//
//  ShareDayPeriod.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum ShareDayPeriod: Sendable {
    case morning
    case afternoon
    case evening
    case night

    static func forDate(_ date: Date, calendar: Calendar = .current) -> ShareDayPeriod {
        switch calendar.component(.hour, from: date) {
        case 5..<12: return .morning
        case 12..<16: return .afternoon
        case 16..<20: return .evening
        default: return .night
        }
    }
}
