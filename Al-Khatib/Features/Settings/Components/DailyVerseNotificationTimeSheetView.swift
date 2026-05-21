//
//  DailyVerseNotificationTimeSheetView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct DailyVerseNotificationTimeSheetView: View {
    @Binding var hour: Int
    @Binding var minute: Int
    @Environment(\.dismiss) private var dismiss

    @State private var pickerDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Choose when you want your daily verse reminder.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                DatePicker(
                    "Morning reminder",
                    selection: $pickerDate,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal)

                Spacer(minLength: 0)
            }
            .padding(.top, 16)
            .navigationTitle("Reminder time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        applyPickerToBindings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(Color.Token.pureWhite, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            pickerDate = Self.date(hour: hour, minute: minute)
        }
    }

    private func applyPickerToBindings() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: pickerDate)
        hour = components.hour ?? DailyVerseNotificationPreferences.defaultHour
        minute = components.minute ?? DailyVerseNotificationPreferences.defaultMinute
    }

    private static func date(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
