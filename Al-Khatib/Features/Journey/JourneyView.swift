//
//  JourneyView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct JourneyView: View {
    @Environment(\.appContainer) private var container
    var verseState: TodayVerseState

    @State private var selectedSegment: JourneySegment = .reflection

    var body: some View {
        ZStack {
            Color.Theme.offWhite.ignoresSafeArea()

            if verseState.isLoggedIn {
                journeyContent
            }
        }
        .onAppear {
            Task { @MainActor in
                await verseState.refreshProfile(container: container)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                await verseState.refreshProfile(container: container)
            }
        }
    }

    private var journeyContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                JourneySegmentedControl(selection: $selectedSegment)
                    .padding(.horizontal)
                segmentPanel
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
    }

    private var header: some View {
        HStack {
            Text("Journey")
                .font(.largeTitle.bold())
                .foregroundColor(Color.Theme.deepEmerald)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 24)
    }

    @ViewBuilder
    private var segmentPanel: some View {
        Group {
            switch selectedSegment {
            case .reflection:
                JourneyReflectionPanel()
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            case .dayActive:
                JourneyDayActivePanel()
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            case .consistency:
                JourneyConsistencyPanel()
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            case .dayStreak:
                JourneyDayStreakPanel()
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.22), value: selectedSegment)
    }
}

private enum JourneySegment: Int, CaseIterable, Identifiable {
    case reflection
    case dayActive
    case consistency
    case dayStreak

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .reflection: "Reflection"
        case .dayActive: "Day Active"
        case .consistency: "Consistency"
        case .dayStreak: "Day Streak"
        }
    }

    var shortTitle: String {
        switch self {
        case .reflection: "Reflect"
        case .dayActive: "Active"
        case .consistency: "Consist."
        case .dayStreak: "Streak"
        }
    }
}

private struct JourneySegmentedControl: View {
    @Binding var selection: JourneySegment
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 0) {
            ForEach(JourneySegment.allCases) { segment in
                segmentButton(segment)
            }
        }
        .padding(3)
        .background(Color.Theme.softGrey.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Journey metrics")
    }

    private func segmentButton(_ segment: JourneySegment) -> some View {
        let isSelected = selection == segment
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selection = segment
            }
        } label: {
            Text(label(for: segment))
                .font(.subheadline.weight(isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? Color.Theme.deepEmerald : Color.primary.opacity(0.45))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.Theme.pureWhite)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func label(for segment: JourneySegment) -> String {
        if dynamicTypeSize >= .accessibility1 {
            return segment.shortTitle
        }
        return segment.title
    }
}

private struct JourneyReflectionPanel: View {
    var body: some View {
        JourneyStatRowCard(
            icon: "book.closed.fill",
            title: "Total Reflections",
            value: "0"
        )
    }
}

private struct JourneyDayActivePanel: View {
    var body: some View {
        JourneyStatRowCard(
            icon: "calendar",
            title: "Days Active",
            value: "0"
        )
    }
}

private struct JourneyStatRowCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.Theme.deepEmerald)
                .frame(width: 40, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 8)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(Color.Theme.deepEmerald)
                .contentTransition(.numericText())
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
        .flatCard()
    }
}

private struct JourneyConsistencyPanel: View {
    /// Static 12×7 grid pattern (decorative only).
    private static let pattern: [Bool] = {
        // Column-major, 12 weeks × 7 rows; true = “filled” cell
        let bits: [[Bool]] = [
            [false, false, true, false, true, false, false],
            [false, true, true, true, false, false, true],
            [true, true, false, true, true, false, false],
            [false, true, true, false, true, true, true],
            [true, false, true, true, false, true, false],
            [false, true, false, true, true, true, false],
            [true, true, true, false, false, true, true],
            [false, false, true, true, true, false, true],
            [true, false, false, true, false, true, true],
            [true, true, false, false, true, false, true],
            [false, true, true, true, true, false, false],
            [true, false, true, false, true, true, false],
        ]
        return bits.flatMap { $0 }
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reading Consistency")
                    .font(.headline)
                    .foregroundStyle(Color.Theme.deepEmerald)
                Text("Last 12 weeks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            let cols = 12
            let rows = 7
            HStack(spacing: 4) {
                ForEach(0..<cols, id: \.self) { col in
                    VStack(spacing: 4) {
                        ForEach(0..<rows, id: \.self) { row in
                            let idx = col * rows + row
                            let filled = Self.pattern.indices.contains(idx) ? Self.pattern[idx] : false
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(filled ? Color.Theme.deepEmerald : Color.Theme.softGrey.opacity(0.35))
                                .frame(width: 14, height: 14)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        .flatCard()
    }
}

private struct JourneyDayStreakPanel: View {
    private static let weekLabels = ["S", "S", "M", "T", "W", "T", "F"]
    private static let activeFlags = [false, false, true, true, true, false, false]

    var body: some View {
        VStack(spacing: 18) {
            Text("0")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(Color.Theme.deepEmerald)
                .contentTransition(.numericText())

            Text("Day Streak")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Text("Consecutive Days Active")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                ForEach(Array(zip(Self.weekLabels.indices, Self.weekLabels)), id: \.0) { index, label in
                    VStack(spacing: 6) {
                        Text(label)
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                        Circle()
                            .fill(Self.activeFlags[index] ? Color.Theme.deepEmerald : Color.clear)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(
                                        Self.activeFlags[index] ? Color.Theme.deepEmerald : Color.Theme.softGrey,
                                        lineWidth: 2
                                    )
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 280)
        .flatCard()
    }
}
