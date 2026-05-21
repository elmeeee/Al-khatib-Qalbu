//
//  TodayOrnamentalDividerView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct TodayOrnamentalDividerView: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.Theme.softGrey.opacity(0.1), Color.Theme.gold.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Text("◆")
                .font(.system(size: 6))
                .foregroundColor(Color.Theme.gold.opacity(0.6))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.Theme.gold.opacity(0.3), Color.Theme.softGrey.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }
}
