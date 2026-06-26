//
//  AlKhatibCardModifier.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct FlatCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.Token.pureWhite)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.Token.softGrey, lineWidth: 1)
            )
    }
}

extension View {
    func flatCard() -> some View {
        self.modifier(FlatCardModifier())
    }
}
