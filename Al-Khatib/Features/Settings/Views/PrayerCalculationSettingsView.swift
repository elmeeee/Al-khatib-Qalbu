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

    @State private var searchText = ""

    private var selectedMethod: PrayerCalculationMethod {
        PrayerCalculationMethod(rawValue: methodRawValue) ?? .muhammadiyah
    }

    private var filteredSections: [PrayerCalculationMethod.Section] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else {
            return PrayerCalculationMethod.Section.allCases
        }
        return PrayerCalculationMethod.Section.allCases.compactMap { section in
            let methods = section.methods.filter { method in
                method.displayName.localizedCaseInsensitiveContains(query)
                    || method.organization.localizedCaseInsensitiveContains(query)
                    || method.region.localizedCaseInsensitiveContains(query)
            }
            return methods.isEmpty ? nil : section
        }
    }

    var body: some View {
        List {
            Section {
                selectedMethodBanner
            }

            ForEach(filteredSections) { section in
                Section(section.rawValue) {
                    ForEach(methods(in: section)) { method in
                        methodRow(method)
                    }
                }
            }

            if filteredSections.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search methods")
        .navigationTitle("Prayer calculation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectedMethodBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.title2)
                .foregroundStyle(Color.Theme.deepEmerald)
                .frame(width: 44, height: 44)
                .background(Color.Theme.deepEmerald.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Currently selected")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(selectedMethod.displayName)
                    .font(.headline)
                Text(selectedMethod.organization)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    private func methods(in section: PrayerCalculationMethod.Section) -> [PrayerCalculationMethod] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return section.methods }
        return section.methods.filter { method in
            method.displayName.localizedCaseInsensitiveContains(query)
                || method.organization.localizedCaseInsensitiveContains(query)
        }
    }

    private func methodRow(_ method: PrayerCalculationMethod) -> some View {
        Button {
            select(method)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.displayName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(method.organization)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if method == selectedMethod {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.Theme.deepEmerald)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func select(_ method: PrayerCalculationMethod) {
        guard methodRawValue != method.rawValue else { return }
        methodRawValue = method.rawValue
        method.persist()
    }
}
