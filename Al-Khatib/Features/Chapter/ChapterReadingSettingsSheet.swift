//
//  ChapterReadingSettingsSheet.swift
//  Al-Khatib
//

import SwiftUI

struct ChapterReadingSettingsSheetContent: View {
    @Bindable var viewModel: ChapterVersesViewModel
    @Binding var fontScale: Double
    @Binding var showTranslation: Bool
    let onPreferencesChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var preferencesReady = false
    @State private var lastRecitationId: Int?

    var body: some View {
        ChapterReadingSettingsSheet(
            fontScale: $fontScale,
            showTranslation: $showTranslation,
            selectedRecitationId: $viewModel.selectedRecitationId,
            recitations: viewModel.recitations,
            isLoadingRecitations: viewModel.recitations.isEmpty && viewModel.isLoading,
            isApplyingPreferences: viewModel.isReloadingContent
        )
        .task {
            await viewModel.loadRecitationsIfNeeded()
            lastRecitationId = viewModel.selectedRecitationId
            preferencesReady = true
        }
        .onChange(of: viewModel.selectedRecitationId) { _, newValue in
            guard preferencesReady, lastRecitationId != newValue else { return }
            lastRecitationId = newValue
            onPreferencesChange()
        }
    }
}

struct ChapterReadingSettingsSheet: View {
    @Binding var fontScale: Double
    @Binding var showTranslation: Bool
    @Binding var selectedRecitationId: Int
    let recitations: [RecitationPayload]
    let isLoadingRecitations: Bool
    let isApplyingPreferences: Bool

    @Environment(\.dismiss) private var dismiss

    private let fontScaleRange: ClosedRange<Double> = 0.85 ... 1.35

    var body: some View {
        NavigationStack {
            Form {
                recitationSection

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
        .presentationDetents([.medium, .large])
    }

    private var recitationSection: some View {
        Section {
            if isLoadingRecitations && recitations.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if recitations.isEmpty {
                Text("Reciters unavailable")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Picker("Reciter", selection: $selectedRecitationId) {
                    ForEach(recitations, id: \.identifiableId) { recitation in
                        Text(recitation.displayName).tag(recitation.identifiableId)
                    }
                }
                .pickerStyle(.menu)
                .disabled(isApplyingPreferences)
            }

            if isApplyingPreferences {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Loading verses…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            Text("Updates audio for all verses in this surah.")
        }
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
