//
//  ChapterRevelationBadge.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ChapterRevelationBadge: View {
    let chapter: QuranChapter

    var body: some View {
        if chapter.revelationLabel.isEmpty == false {
            Text(chapter.revelationLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(foregroundColor)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(foregroundColor.opacity(0.12)))
        }
    }

    private var foregroundColor: Color {
        chapter.isMeccan ? Color.Token.gold : Color.Token.blueLink
    }
}
