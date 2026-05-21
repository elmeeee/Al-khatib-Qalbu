//
//  TranslatorSelectionSheetView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct TranslatorSelectionSheetView: View {
    @Binding var selectedTranslationId: Int
    @Binding var selectedTranslationName: String

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TranslatorSelectionViewModel

    init(
        selectedTranslationId: Binding<Int>,
        selectedTranslationName: Binding<String>,
        contentRepository: QuranContentRepository
    ) {
        _selectedTranslationId = selectedTranslationId
        _selectedTranslationName = selectedTranslationName
        _viewModel = State(initialValue: TranslatorSelectionViewModel(contentRepository: contentRepository))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ZStack {
                Color.Token.screenBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar(viewModel: viewModel)

                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading translators...")
                            .tint(Color.Token.teal)
                        Spacer()
                    } else if let errorMessage = viewModel.errorMessage {
                        errorState(errorMessage)
                    } else {
                        translatorList
                    }
                }
            }
            .navigationTitle("Select Translator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .tint(Color.Token.teal)
                }
            }
            .task {
                await viewModel.loadTranslations()
            }
        }
    }

    private func searchBar(viewModel: TranslatorSelectionViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search translators or languages...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            if viewModel.searchQuery.isEmpty == false {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.Token.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var translatorList: some View {
        List(viewModel.filteredTranslations) { trans in
            Button {
                selectedTranslationId = trans.id
                selectedTranslationName = viewModel.displayName(for: trans)
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.displayName(for: trans))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.Token.slate800)
                        Text(viewModel.subtitle(for: trans))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if trans.id == selectedTranslationId {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.Token.teal)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.Token.pureWhite)
        }
        .scrollContentBackground(.hidden)
    }

    private func errorState(_ message: String) -> some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 44))
                    .foregroundColor(.red)
                Text(message)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button("Try Again") {
                    Task { await viewModel.loadTranslations() }
                }
                .tint(Color.Token.teal)
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
    }
}
