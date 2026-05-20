//
//  AyahArabicWebBlock.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct AyahArabicWebBlock: View {
    let payload: RandomAyahPayload
    var style: HTMLContentStyle = .verseCard
    var fontScale: Double = 1.0
    var measuredHeight: Binding<CGFloat>?

    @State private var webHeight: CGFloat = 160

    var body: some View {
        HTMLContentWebView(
            htmlFragment: payload.tajweedWebHTMLFragment(),
            style: style,
            rendersTajweedHTML: true,
            fontScale: fontScale,
            contentHeight: $webHeight
        )
        .frame(height: webHeight)
        .frame(maxWidth: .infinity)
        .clipped()
        .allowsHitTesting(false)
        .animation(nil, value: webHeight)
        .id(stableId)
        .onChangeWithFallback(of: reloadKey) { _ in
            webHeight = 160
            measuredHeight?.wrappedValue = 160
        }
        .onChangeWithFallback(of: webHeight) { height in
            measuredHeight?.wrappedValue = height
        }
    }

    private var stableId: String {
        let base: String
        if let key = payload.verseKey {
            base = key
        } else if let id = payload.id {
            base = "id-\(id)"
        } else {
            base = "ayah"
        }
        return "\(base)-tajweed-\(style)-\(fontScale)"
    }

    private var reloadKey: String {
        "\(payload.verseKey ?? "")-\(fontScale)"
    }
}
