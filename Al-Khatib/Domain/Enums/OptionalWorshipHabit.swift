//
//  OptionalWorshipHabit.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

public enum OptionalWorshipHabit: String, CaseIterable, Identifiable, Sendable {
    case qiyamulLail = "QIYAMUL_LAIL"
    case mondayThursdayFast = "MONDAY_THURSDAY_FAST"
    case ayyamulBidhSahur = "AYYAMUL_BIDH_SAHUR"

    public var id: String { rawValue }

    public var prefKey: String {
        switch self {
        case .qiyamulLail: return "qiyam"
        case .mondayThursdayFast: return "mon_thu_fast"
        case .ayyamulBidhSahur: return "ayyamul_bidh_sahur"
        }
    }
}
