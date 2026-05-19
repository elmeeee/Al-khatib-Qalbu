//
//  ChapterReadingSettingsSheet.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ChapterReadingSettingsSheet: View {
    @Binding var fontScale: Double
    @Binding var showTranslation: Bool
    @Environment(\.dismiss) private var dismiss

    private let fontScaleRange: ClosedRange<Double> = 0.85 ... 1.35

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Text size")
                            Spacer()
                            Text(fontScaleLabel)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $fontScale, in: fontScaleRange, step: 0.05)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Arabic & translation")
                }

                Section {
                    Toggle("Show translation", isOn: $showTranslation)
                }
            }
            .navigationTitle("Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
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
