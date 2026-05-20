//
//  AyahArabicNativeBlock.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct AyahArabicNativeBlock: View {
    let text: String
    var style: HTMLContentStyle = .verseCard
    var fontScale: Double = 1.0
    var measuredHeight: Binding<CGFloat>?

    @State private var textHeight: CGFloat = 120

    private var fontSize: CGFloat {
        CGFloat(24 * min(max(fontScale, 0.85), 1.45))
    }

    private var lineSpacing: CGFloat {
        fontSize * 0.42
    }

    var body: some View {
        Text(text)
            .font(AlKhatibTypography.quranArabic(size: fontSize))
            .foregroundStyle(foregroundColor)
            .multilineTextAlignment(.center)
            .lineSpacing(lineSpacing)
            .frame(maxWidth: .infinity, alignment: .center)
            .fixedSize(horizontal: false, vertical: true)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { reportHeight(proxy.size.height) }
                        .onChange(of: proxy.size.height) { _, height in
                            reportHeight(height)
                        }
                }
            }
            .frame(minHeight: textHeight)
    }

    private var foregroundColor: Color {
        switch style {
        case .verseCardOnDark:
            return .white
        case .verseCard, .article, .tafsirReader:
            return Color.primary
        }
    }

    private func reportHeight(_ height: CGFloat) {
        let clamped = min(max(height + 8, 80), 520)
        guard abs(textHeight - clamped) > 0.5 else { return }
        textHeight = clamped
        measuredHeight?.wrappedValue = clamped
    }
}
