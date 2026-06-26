//
//  ReflectPostText.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectPostText: View {
    let text: String
    var foreground: Color = .primary
    var fontSize: CGFloat = 15

    var body: some View {
        Text(ReflectPostFormatting.attributedString(from: text))
            .font(.system(size: fontSize))
            .lineSpacing(3)
            .foregroundColor(foreground)
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
