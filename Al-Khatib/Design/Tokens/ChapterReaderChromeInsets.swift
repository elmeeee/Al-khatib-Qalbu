//
//  ChapterReaderChromeInsets.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ChapterReaderChromeInsets: Equatable {
    var top: CGFloat = 56
    var bottom: CGFloat = 88

    private static let headerRowHeight: CGFloat = 56
    private static let topContentGap: CGFloat = 28
    private static let bottomContentGap: CGFloat = 24
    private static let tabBarClearance: CGFloat = 56

    static func resolved(safeArea: EdgeInsets, showsNowPlaying: Bool) -> ChapterReaderChromeInsets {
        let top = safeArea.top + headerRowHeight + topContentGap
        let playerClearance = showsNowPlaying ? TabBarLayout.nowPlayingChromeHeight + 12 : 0
        let bottom = safeArea.bottom + tabBarClearance + playerClearance + bottomContentGap
        return ChapterReaderChromeInsets(top: top, bottom: bottom)
    }
}

private struct ChapterReaderChromeInsetsKey: EnvironmentKey {
    static let defaultValue = ChapterReaderChromeInsets()
}

extension EnvironmentValues {
    var chapterReaderChromeInsets: ChapterReaderChromeInsets {
        get { self[ChapterReaderChromeInsetsKey.self] }
        set { self[ChapterReaderChromeInsetsKey.self] = newValue }
    }
}
