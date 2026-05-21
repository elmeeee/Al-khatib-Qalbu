//
//  ChapterReaderBackground.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ChapterReaderBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.Token.readerMoss,
                Color.Token.deepEmerald,
                Color.Token.readerForest
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension View {
    func chapterReaderScreenBackground() -> some View {
        background {
            ChapterReaderBackground()
                .ignoresSafeArea()
        }
    }
}
