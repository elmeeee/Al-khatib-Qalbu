//
//  TikTokSideActionButton.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct QFSideActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color.black.opacity(0.35)))
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
            }
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }
}
