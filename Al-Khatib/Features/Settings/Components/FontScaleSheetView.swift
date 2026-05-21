//
//  FontScaleSheetView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct FontScaleSheetView: View {
    @Binding var fontScale: Double
    @Environment(\.dismiss) private var dismiss

    private let fontScaleRange: ClosedRange<Double> = 0.85 ... 1.35

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Sample Arabic Typography")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                        .font(.system(size: 26 * fontScale, weight: .semibold, design: .serif))
                        .foregroundColor(Color.Token.deepEmerald)
                        .multilineTextAlignment(.center)

                    Text("In the name of Allah, the Entirely Merciful, the Especially Merciful.")
                        .font(.system(size: 14 * fontScale))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(Color.Token.lightGrey, in: RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 16) {
                    Text("A")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)

                    Slider(value: $fontScale, in: fontScaleRange, step: 0.05)
                        .tint(Color.Token.teal)

                    Text("A")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)

                Text(fontScaleLabel)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.Token.teal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.Token.teal.opacity(0.1))
                    .clipShape(Capsule())

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.Token.teal)
                        .clipShape(Capsule())
                }
                .padding(.top, 12)
            }
            .padding(24)
            .navigationTitle("Font Size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .tint(Color.Token.teal)
                }
            }
        }
        .presentationDetents([.fraction(0.55)])
    }

    private var fontScaleLabel: String {
        switch fontScale {
        case ..<0.95: "Small"
        case 0.95 ..< 1.1: "Medium"
        case 1.1 ..< 1.22: "Large"
        default: "Extra large"
        }
    }
}
