//
//  ChaptersView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ChaptersView: View {
    @Environment(\.appContainer) private var container
    @State private var vm: QuranChaptersViewModel?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.Theme.offWhite.ignoresSafeArea()

                if let vm {
                    quranContent(vm)
                } else {
                    LoadingSkeleton()
                }
            }
            .navigationDestination(for: QuranChapter.self) { chapter in
                ChapterVersesView(chapter: chapter)
            }
        }
        .task {
            guard let c = container, vm == nil else { return }
            let model = QuranChaptersViewModel(content: c.content)
            vm = model
            await model.loadChapters()
        }
    }

    @ViewBuilder
    private func quranContent(_ vm: QuranChaptersViewModel) -> some View {
        @Bindable var bindable = vm

        VStack(spacing: 0) {
            header

            if bindable.isLoading && bindable.chapters.isEmpty {
                chaptersLoadingBody
            } else if let error = bindable.errorMessage, bindable.chapters.isEmpty {
                chaptersErrorBody(error) {
                    Task { await bindable.loadChapters(force: true) }
                }
            } else if bindable.chapters.isEmpty {
                chaptersEmptyBody
            } else {
                chaptersList(bindable)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            Text("Quran")
                .font(.largeTitle.bold())
                .foregroundColor(Color.Theme.deepEmerald)
            Spacer()
            if let vm, vm.isLoading == false {
                Button {
                    Task { await vm.loadChapters(force: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.Theme.deepEmerald)
                }
                .accessibilityLabel("Refresh chapters")
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }

    private var chaptersLoadingBody: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(0..<8, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.Theme.softGrey.opacity(0.35))
                        .frame(height: 72)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .redacted(reason: .placeholder)
    }

    private func chaptersErrorBody(_ message: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(Color.Theme.deepEmerald.opacity(0.5))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(Color.Theme.deepEmerald)
            Spacer()
        }
    }

    private var chaptersEmptyBody: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(Color.Theme.deepEmerald.opacity(0.5))
            Text("No chapters found")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private func chaptersList(_ vm: QuranChaptersViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(vm.chapters) { chapter in
                    NavigationLink(value: chapter) {
                        QuranChapterRow(chapter: chapter)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .refreshable {
            await vm.loadChapters(force: true)
        }
    }
}

private struct QuranChapterRow: View {
    let chapter: QuranChapter

    var body: some View {
        HStack(spacing: 14) {
            Text("\(chapter.id)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color.Theme.pureWhite)
                .frame(width: 36, height: 36)
                .background(Color.Theme.deepEmerald)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.displayComplexName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if chapter.displayTranslatedName.isEmpty == false {
                    Text(chapter.displayTranslatedName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.Theme.deepEmerald)
                        .lineLimit(2)
                }

                if let countLabel = chapter.versesCountLabel {
                    Text(countLabel)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 8)

            if let arabic = chapter.nameArabic, arabic.isEmpty == false {
                Text(arabic)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.Theme.deepEmerald)
                    .multilineTextAlignment(.trailing)
                    .environment(\.layoutDirection, .rightToLeft)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.Theme.softGrey)
        }
        .padding(14)
        .flatCard()
    }
}
