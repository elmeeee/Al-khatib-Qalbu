//
//  PrayerCalculationSettingsView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct PrayerCalculationSettingsView: View {
    @AppStorage(PrayerCalculationMethod.storageKey)
    private var methodRawValue = PrayerCalculationMethod.defaultMethod.rawValue

    @Environment(\.dismiss) private var dismiss

    private var selectedMethod: PrayerCalculationMethod {
        PrayerCalculationMethod(rawValue: methodRawValue) ?? .muhammadiyah
    }

    var body: some View {
        Form {
            Section {
                ForEach(PrayerCalculationMethod.allCases) { method in
                    Button {
                        select(method)
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(method.displayName)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text(method.region)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if method == selectedMethod {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.Theme.deepEmerald)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Calculation method")
            } footer: {
                Text("Prayer times on Today use this method via the Aladhan API. Indonesia defaults to Muhammadiyah; other countries use their national standard when location is detected.")
            }

        }
        .navigationTitle("Prayer times")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func select(_ method: PrayerCalculationMethod) {
        guard methodRawValue != method.rawValue else { return }
        methodRawValue = method.rawValue
        method.persist()
    }
}
