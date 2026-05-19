//
//  TabBarLayout.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import CoreGraphics

enum TabBarLayout {
    static let horizontalInset: CGFloat = 26
    static let nowPlayingHorizontalInset: CGFloat = 64
    static let chromeCornerRadius: CGFloat = 20
    static let spacingAboveTabBar: CGFloat = 12
    static let nowPlayingBarHeight: CGFloat = 52
    static let nowPlayingBottomPadding: CGFloat = 8

    static var nowPlayingChromeHeight: CGFloat {
        spacingAboveTabBar + nowPlayingBarHeight + nowPlayingBottomPadding
    }
}
