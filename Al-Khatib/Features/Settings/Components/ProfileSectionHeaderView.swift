//
//  ProfileSectionHeaderView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ProfileSectionHeaderView: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            // Accent bar — matches Android's vertical colored bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.Token.deepEmerald)
                .frame(width: 3, height: 16)

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.Token.slate800)

            Spacer()
        }
        .padding(.leading, 4)
        .accessibilityAddTraits(.isHeader)
    }
}
