//
//  ChapterReadingSettingsSheet.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
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
    @ObservedObject private var languageManager = AppLanguageManager.shared

    private let fontScaleRange: ClosedRange<Double> = 0.85 ... 1.35

    var body: some View {
        NavigationStack {
            Form {
                recitationSection

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(languageManager.localize("text_size"))
                            Spacer()
                            Text(fontScaleLabel)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $fontScale, in: fontScaleRange, step: 0.05)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(languageManager.localize("arabic_translation_header"))
                }

                Section {
                    Toggle(languageManager.localize("show_translation"), isOn: $showTranslation)
                }
            }
            .navigationTitle(languageManager.localize("reading_settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localize("done")) { dismiss() }
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
                Text(languageManager.localize("reciters_unavailable"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Picker(languageManager.localize("reciter"), selection: $selectedRecitationId) {
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
                    Text(languageManager.localize("loading_verses"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            Text(languageManager.localize("reciter_audio_update_desc"))
        }
    }

    private var fontScaleLabel: String {
        switch fontScale {
        case ..<0.95: languageManager.localize("font_small")
        case 0.95 ..< 1.1: languageManager.localize("font_medium")
        case 1.1 ..< 1.22: languageManager.localize("font_large")
        default: languageManager.localize("font_extra_large")
        }
    }
}
