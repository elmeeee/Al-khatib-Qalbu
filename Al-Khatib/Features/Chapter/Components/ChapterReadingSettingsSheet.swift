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

    @AppStorage("chapterReaderShowTransliteration") private var showTransliteration = true
    @AppStorage("chapterReaderMemorizationMode") private var isMemorizationMode = false
    @AppStorage("chapterReaderContinuousPlay") private var isContinuousPlay = true

    private let fontScaleRange: ClosedRange<Double> = 0.85 ... 1.35

    var body: some View {
        NavigationStack {
            Form {
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
                        Picker(selection: $selectedRecitationId) {
                            ForEach(recitations, id: \.identifiableId) { recitation in
                                Text(recitation.displayName).tag(recitation.identifiableId)
                            }
                        } label: {
                            Label(languageManager.localize("reciter"), systemImage: "person.wave.2.fill")
                                .foregroundColor(Color.Token.deepEmerald)
                        }
                        .pickerStyle(.menu)
                        .disabled(isApplyingPreferences)
                    }
                } header: {
                    Text(languageManager.localize("reciter") ?? "Reciter")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(languageManager.localize("text_size"), systemImage: "textformat.size")
                                .foregroundColor(Color.Token.deepEmerald)
                            Spacer()
                            Text(fontScaleLabel)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color.Token.gold)
                        }
                        Slider(value: $fontScale, in: fontScaleRange, step: 0.05)
                            .tint(Color.Token.deepEmerald)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(languageManager.localize("text_size") ?? "Text Display")
                }

                Section {
                    Toggle(isOn: $showTranslation) {
                        Label(languageManager.localize("show_translation") ?? "Show Translation", systemImage: "character.book.closed.fill")
                            .foregroundColor(Color.Token.deepEmerald)
                    }
                    .tint(Color.Token.deepEmerald)

                    Toggle(isOn: $showTransliteration) {
                        Label(languageManager.localize("show_transliteration") ?? "Tampilkan Latin", systemImage: "abc")
                            .foregroundColor(Color.Token.deepEmerald)
                    }
                    .tint(Color.Token.deepEmerald)

                    Toggle(isOn: $isMemorizationMode) {
                        Label(languageManager.localize("memorization_mode") ?? "Mode Hafalan", systemImage: "brain.headlight")
                            .foregroundColor(Color.Token.deepEmerald)
                    }
                    .tint(Color.Token.deepEmerald)
                } header: {
                    Text(languageManager.localize("arabic_translation_header"))
                }

                Section {
                    Toggle(isOn: $isContinuousPlay) {
                        Label(languageManager.localize("continuous_play") ?? "Putar Berkelanjutan", systemImage: "arrow.forward.to.line.circle.fill")
                            .foregroundColor(Color.Token.deepEmerald)
                    }
                    .tint(Color.Token.deepEmerald)
                } header: {
                    Text("Audio Control")
                }
            }
            .navigationTitle(languageManager.localize("reading_settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localize("done")) { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(Color.Token.deepEmerald)
                }
            }
        }
        .presentationDetents([.medium, .large])
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
