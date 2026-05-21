//
//  ReflectReelPostBodyView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectReelPostBodyView: View {
    let post: ReflectFeedPost

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                if let body = post.body, body.isEmpty == false {
                    ReflectPostText(text: body, foreground: .white, fontSize: 16)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(post.spokenAccessibilitySummary)
        .accessibilityAddTraits(.isStaticText)
    }
}
