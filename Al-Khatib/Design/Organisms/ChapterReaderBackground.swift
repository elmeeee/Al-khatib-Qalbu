//
//  ChapterReaderBackground.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ChapterReaderBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.Token.readerForest, Color.Token.forestDeeper],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Soft radial ambient glow
            GeometryReader { geo in
                RadialGradient(
                    colors: [Color.Token.gold.opacity(0.12), Color.clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: min(geo.size.width, geo.size.height) * 0.65
                )
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea()
        }
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
