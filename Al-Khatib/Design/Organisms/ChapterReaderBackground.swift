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
        Color.Token.screenBackground
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
