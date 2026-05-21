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
        Text(title)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Color.Token.slate500)
            .padding(.leading, 4)
            .accessibilityAddTraits(.isHeader)
    }
}
