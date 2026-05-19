//
//  AyahArabicWebBlock.swift
//  Al-Khatib
//

import SwiftUI

struct AyahArabicWebBlock: View {
    let payload: RandomAyahPayload
    @State private var webHeight: CGFloat = 160

    var body: some View {
        HTMLContentWebView(
            htmlFragment: payload.arabicFragmentForWebView(),
            style: .verseCard,
            contentHeight: $webHeight
        )
        .frame(height: webHeight)
        .animation(nil, value: webHeight)
        .frame(maxWidth: .infinity)
        .id(stableId)
        .onChangeWithFallback(of: payload.verseKey ?? "") { _ in webHeight = 160 }
    }

    private var stableId: String {
        if let key = payload.verseKey { return key }
        if let id = payload.id { return "id-\(id)" }
        return "ayah"
    }
}
