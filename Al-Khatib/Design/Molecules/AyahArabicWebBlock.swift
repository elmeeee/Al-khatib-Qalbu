//
//  AyahArabicWebBlock.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct AyahArabicWebBlock: View {
    static let placeholderHeight: CGFloat = 72

    let payload: RandomAyahPayload
    var style: HTMLContentStyle = .verseCard
    var fontScale: Double = 1.0
    var measuredHeight: Binding<CGFloat>?
    var includeTranslationInAccessibility: Bool = false

    @State private var webHeight: CGFloat = placeholderHeight

    var body: some View {
        HTMLContentWebView(
            htmlFragment: payload.tajweedWebHTMLFragment(),
            style: style,
            rendersTajweedHTML: true,
            fontScale: fontScale,
            contentHeight: $webHeight
        )
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(height: webHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(payload.spokenAccessibilitySummary(includeTranslation: includeTranslationInAccessibility))
        .accessibilityAddTraits(.isStaticText)
        .allowsHitTesting(false)
        .animation(nil, value: webHeight)
        .id(stableId)
        .onChangeWithFallback(of: reloadKey) { _ in
            webHeight = Self.placeholderHeight
            measuredHeight?.wrappedValue = Self.placeholderHeight
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
