//
//  MascotPopOutView.swift
//  Al-Khatib
//
//  Created by Antigravity on 20/05/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct MascotPopOutView: View {
    let theme: ThematicTheme
    
    init(theme: ThematicTheme) {
        self.theme = theme
    }
    
    var body: some View {
        ZStack {
            if hasAsset(named: theme.mascotImageName) {
                Image(theme.mascotImageName)
                    .resizable()
                    .scaledToFit()
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 4)
            }
        }
    }
    
    private func hasAsset(named name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #else
        return false
        #endif
    }
}
