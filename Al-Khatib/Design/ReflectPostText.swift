//
//  ReflectPostText.swift
//  Al-Khatib
//

import SwiftUI

/// Renders Quran Reflect post bodies: `*bold*` and `_italic_` (WhatsApp-style).
struct ReflectPostText: View {
    let text: String

    var body: some View {
        Text(ReflectPostFormatting.attributedString(from: text))
            .font(.system(size: 15))
            .lineSpacing(3)
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
    }
}

enum ReflectPostFormatting {
    static func attributedString(from text: String) -> AttributedString {
        var result = AttributedString()
        var index = text.startIndex

        while index < text.endIndex {
            let char = text[index]
            if char == "*" || char == "_" {
                let delimiter = char
                let contentStart = text.index(after: index)
                if contentStart < text.endIndex,
                   let end = text[contentStart...].firstIndex(of: delimiter),
                   end > contentStart {
                    let inner = String(text[contentStart..<end])
                    var segment = AttributedString(inner)
                    if delimiter == "*" {
                        segment.inlinePresentationIntent = .stronglyEmphasized
                    } else {
                        segment.inlinePresentationIntent = .emphasized
                    }
                    result.append(segment)
                    index = text.index(after: end)
                    continue
                }
            }

            result.append(AttributedString(String(char)))
            index = text.index(after: index)
        }

        return result
    }
}
