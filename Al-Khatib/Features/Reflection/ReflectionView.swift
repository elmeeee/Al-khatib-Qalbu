//
//  ReflectionView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectionView: View {
    @Environment(\.appContainer) private var container
    @State private var vm: ReflectionViewModel?
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastIsError = false

    let verseState: TodayVerseState

    var body: some View {
        ZStack {
            if container != nil {
                if let m = vm {
                    mainContent(m)
                } else {
                    LoadingSkeleton()
                }
            }
        }
        .overlay(alignment: .top) {
            if showToast {
                Text(toastMessage)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(toastIsError ? Color.red : Color.Theme.deepEmerald)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .onAppear {
            if let c = container, vm == nil {
                vm = ReflectionViewModel(container: c)
            }

            if let key = verseState.activeVerseKey {
                vm?.verseKey = key
            }
        }
        .onChange(of: verseState.activeVerseKey) { _, newKey in
            if let key = newKey {
                vm?.verseKey = key
            }
        }
    }

    @ViewBuilder
    private func mainContent(_ m: ReflectionViewModel) -> some View {
        ZStack {
            Color.Theme.offWhite.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Reflect")
                        .font(.largeTitle.bold())
                        .foregroundColor(Color.Theme.deepEmerald)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 16) {
                        // Verse Reference Banner
                        verseReferenceBanner

                        // Editor Card
                        editorCard(m)

                        // Save Button
                        saveButton(m)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var verseReferenceBanner: some View {
        Group {
            if let label = verseState.activeVerseLabel {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.Theme.gold)
                        Text("Reflecting on")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Text(label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.Theme.deepEmerald)

                    if let arabic = verseState.activeArabicSnippet, arabic.isEmpty == false {
                        Text(arabic)
                            .font(AlKhatibTypography.quranArabic(size: 19))
                            .multilineTextAlignment(.trailing)
                            .environment(\.layoutDirection, .rightToLeft)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, 2)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.Theme.deepEmerald.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.Theme.deepEmerald.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    private func editorCard(_ m: ReflectionViewModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your Reflection")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.Theme.deepEmerald)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 4)

            ZStack(alignment: .topLeading) {
                if m.text.isEmpty {
                    Text("What does this ayah mean to you today?")
                        .foregroundColor(Color.Theme.softGrey)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
                TextEditor(text: binding(for: m, keyPath: \.text))
                    .font(.body)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 160)
            }

            if let e = m.lastError {
                Text(e)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.Theme.softGrey, lineWidth: 1))
    }

    @ViewBuilder
    private func saveButton(_ m: ReflectionViewModel) -> some View {
        Button(action: {
            Task {
                let msg = await m.saveAndSync()
                toastMessage = msg
                toastIsError = false
                withAnimation { showToast = true }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation { showToast = false }
            }
        }) {
            HStack(spacing: 8) {
                if m.isSyncing {
                    ProgressView().tint(.white)
                }
                Text("Save & Sync")
                    .font(.headline)
            }
        }
        .buttonStyle(.primaryFlat)
        .disabled(m.text.trimmingCharacters(in: .whitespacesAndNewlines).count < 6)
    }

    private func binding(
        for vm: ReflectionViewModel,
        keyPath: ReferenceWritableKeyPath<ReflectionViewModel, String>
    ) -> Binding<String> {
        Binding(
            get: { vm[keyPath: keyPath] },
            set: { vm[keyPath: keyPath] = $0 }
        )
    }
}
