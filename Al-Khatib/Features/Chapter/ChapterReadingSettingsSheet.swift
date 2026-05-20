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
    @State private var lastRecitationId: Int?
    @State private var lastArabicTextStyle: QuranArabicTextStyle?

    var body: some View {
        ChapterReadingSettingsSheet(
            fontScale: $fontScale,
            showTranslation: $showTranslation,
            selectedRecitationId: $viewModel.selectedRecitationId,
            selectedArabicTextStyle: $viewModel.selectedArabicTextStyle,
            recitations: viewModel.recitations,
            isLoadingRecitations: viewModel.recitations.isEmpty && viewModel.isLoading
        )
        .task {
            await viewModel.loadRecitationsIfNeeded()
            lastRecitationId = viewModel.selectedRecitationId
            lastArabicTextStyle = viewModel.selectedArabicTextStyle
        }
        .onChange(of: viewModel.selectedRecitationId) { _, newValue in
            guard preferencesDidChange(recitationId: newValue, arabicStyle: viewModel.selectedArabicTextStyle) else {
                return
            }
            onPreferencesChange()
        }
        .onChange(of: viewModel.selectedArabicTextStyle) { _, newValue in
            guard preferencesDidChange(recitationId: viewModel.selectedRecitationId, arabicStyle: newValue) else {
                return
            }
            onPreferencesChange()
        }
    }

    private func preferencesDidChange(recitationId: Int, arabicStyle: QuranArabicTextStyle) -> Bool {
        let recitationChanged = lastRecitationId.map { $0 != recitationId } ?? false
        let arabicChanged = lastArabicTextStyle.map { $0 != arabicStyle } ?? false
        lastRecitationId = recitationId
        lastArabicTextStyle = arabicStyle
        return recitationChanged || arabicChanged
    }
}

struct ChapterReadingSettingsSheet: View {
    @Binding var fontScale: Double
    @Binding var showTranslation: Bool
    @Binding var selectedRecitationId: Int
    @Binding var selectedArabicTextStyle: QuranArabicTextStyle
    let recitations: [RecitationPayload]
    let isLoadingRecitations: Bool

    @Environment(\.dismiss) private var dismiss

    private let fontScaleRange: ClosedRange<Double> = 0.85 ... 1.35

    var body: some View {
        NavigationStack {
            Form {
                arabicScriptSection
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

    private var arabicScriptSection: some View {
        Section {
            ForEach(QuranArabicTextStyle.allCases) { style in
                Button {
                    selectedArabicTextStyle = style
                } label: {
                    HStack {
                        Text(style.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if style == selectedArabicTextStyle {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.Theme.deepEmerald)
                        }
                    }
                }
            }
        } header: {
            Text("Arabic script")
        } footer: {
            Text("Changes how Arabic text is fetched and displayed for all verses in this surah.")
        }
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
                ForEach(recitations, id: \.identifiableId) { recitation in
                    Button {
                        selectedRecitationId = recitation.identifiableId
                    } label: {
                        HStack {
                            Text(recitation.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if recitation.identifiableId == selectedRecitationId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.Theme.deepEmerald)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Reciter")
        } footer: {
            Text("Changes the audio recitation for all verses in this surah.")
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
