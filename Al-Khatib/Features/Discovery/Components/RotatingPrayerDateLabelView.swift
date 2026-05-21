//
//  RotatingPrayerDateLabelView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI
import Combine

struct RotatingPrayerDateLabelView: View {
    let hijri: String?
    let gregorian: String?
    var interval: TimeInterval = 7

    @State private var showHijri = true

    private var canRotate: Bool {
        guard let hijri, let gregorian, hijri.isEmpty == false, gregorian.isEmpty == false else {
            return false
        }
        return true
    }

    private var displayedText: String? {
        if canRotate {
            return showHijri ? hijri : gregorian
        }
        if let hijri, hijri.isEmpty == false { return hijri }
        if let gregorian, gregorian.isEmpty == false { return gregorian }
        return nil
    }

    private var dateAccessibilityLabel: String {
        var parts: [String] = []
        if let hijri, hijri.isEmpty == false { parts.append("Hijri date \(hijri)") }
        if let gregorian, gregorian.isEmpty == false { parts.append("Gregorian date \(gregorian)") }
        return parts.isEmpty ? "Date" : parts.joined(separator: ". ")
    }

    var body: some View {
        Group {
            if let displayedText {
                Text(displayedText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.Theme.deepEmerald.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.4), value: showHijri)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
        .accessibilityLabel(dateAccessibilityLabel)
        .onReceive(Timer.publish(every: interval, on: .main, in: .common).autoconnect()) { _ in
            guard canRotate else { return }
            showHijri.toggle()
        }
        .onChange(of: hijri) { _, _ in showHijri = true }
        .onChange(of: gregorian) { _, _ in showHijri = true }
    }
}
