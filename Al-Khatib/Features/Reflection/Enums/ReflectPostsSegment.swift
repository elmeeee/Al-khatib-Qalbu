//
//  ReflectPostsSegment.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum ReflectPostsSegment: String, CaseIterable, Identifiable, Equatable {
    case feed
    case myPosts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feed: return "All Reflect"
        case .myPosts: return "My Reflect"
        }
    }
}
