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
    var arabicTextStyle: QuranArabicTextStyle = .uthmaniTajweed
    var style: HTMLContentStyle = .verseCard
    var fontScale: Double = 1.0
    var measuredHeight: Binding<CGFloat>?

    @State private var webHeight: CGFloat = 160
    @State private var tajweedFontRevision = 0

    private var usesTajweedWeb: Bool {
        payload.shouldUseTajweedWebView(for: arabicTextStyle)
    }

    var body: some View {
        Group {
            if usesTajweedWeb {
                tajweedWebView
            } else if let plain = payload.plainArabicLine(for: arabicTextStyle) {
                AyahArabicNativeBlock(
                    text: plain,
                    style: style,
                    fontScale: fontScale,
                    measuredHeight: measuredHeight
                )
            } else {
                Color.clear
                    .frame(height: 40)
            }
        }
        .frame(maxWidth: .infinity)
        .id(stableId)
        .task(id: usesTajweedWeb) {
            guard usesTajweedWeb else { return }
            for _ in 0..<4 {
                if AlKhatibTypography.verseArabicHTMLBaseDirectory() != nil {
                    tajweedFontRevision &+= 1
                    return
                }
                try? await Task.sleep(nanoseconds: 40_000_000)
            }
        }
    }

    private var tajweedWebView: some View {
        HTMLContentWebView(
            htmlFragment: payload.tajweedWebHTMLFragment(),
            style: style,
            arabicScript: .uthmaniTajweed,
            rendersTajweedHTML: true,
            fontScale: fontScale,
            contentHeight: $webHeight
        )
        .frame(height: webHeight)
        .animation(nil, value: webHeight)
        .background(Color.clear)
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
        let mode = usesTajweedWeb ? "tajweed-web" : "native"
        return "\(base)-\(mode)-\(arabicTextStyle.rawValue)-\(style)-\(fontScale)-f\(tajweedFontRevision)"
    }

    private var reloadKey: String {
        "\(payload.verseKey ?? "")-\(arabicTextStyle.rawValue)-\(fontScale)-\(usesTajweedWeb)-f\(tajweedFontRevision)"
    }
}
