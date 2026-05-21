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
                Color.Token.offWhite.ignoresSafeArea()

                if let vm {
                    quranContent(vm)
                } else {
                    LoadingSkeleton()
                }
            }
            .navigationDestination(for: ChapterReaderRoute.self) { route in
                ChapterVersesView(
                    chapter: route.chapter,
                    initialVerseNumber: route.initialVerseNumber
                )
                .toolbarBackground(.hidden, for: .navigationBar)
            }
        }
        .task {
            guard let c = container, vm == nil else { return }
            let model = QuranChaptersViewModel(
                content: c.content,
                readingSessions: c.readingSessions
            )
            vm = model
            await model.refreshAll()
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
                    Task { await bindable.refreshAll(force: true) }
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Text("\u{2726}")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.Token.gold)
                    Text("Quran")
                        .font(.largeTitle.bold())
                        .foregroundColor(Color.Token.deepEmerald)
                }
            }

            Text("114 Surahs \u{2022} The Noble Quran")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.Token.deepEmerald.opacity(0.55))
                .padding(.leading, 22)

            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.Token.gold, Color.Token.gold.opacity(0.15)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 60, height: 3)
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 14)
    }

    private var chaptersLoadingBody: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(0..<8, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.Token.softGrey.opacity(0.25))
                        .frame(height: 80)
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
                .foregroundColor(Color.Token.deepEmerald.opacity(0.5))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(Color.Token.deepEmerald)
            Spacer()
        }
    }

    private var chaptersEmptyBody: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(Color.Token.deepEmerald.opacity(0.5))
            Text("No chapters found")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private func chaptersList(_ vm: QuranChaptersViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if let route = vm.continueReadingRoute() {
                    NavigationLink(value: route) {
                        ContinueReadingCard(
                            chapter: route.chapter,
                            verseNumber: route.initialVerseNumber ?? 1
                        )
                    }
                    .buttonStyle(.plain)
                }

                ForEach(vm.chapters) { chapter in
                    NavigationLink(value: ChapterReaderRoute(chapter: chapter)) {
                        QuranChapterRow(chapter: chapter)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .refreshable {
            await vm.refreshAll(force: true)
        }
    }
}

private struct ContinueReadingCard: View {
    let chapter: QuranChapter
    let verseNumber: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.Token.gold, Color.Token.goldDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.Token.gold.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Continue reading")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.Token.gold)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(chapter.displayComplexName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("Ayah \(verseNumber)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.Token.gold)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.Token.amberWash],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.Token.gold.opacity(0.4), Color.Token.gold.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.Token.gold.opacity(0.08), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Continue reading \(chapter.displayComplexName), ayah \(verseNumber)")
        .accessibilityHint("Resume where you left off")
    }
}

private struct QuranChapterRow: View {
    let chapter: QuranChapter

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.Token.deepEmerald, Color.Token.tealDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(45))

                Text("\(chapter.id)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(chapter.displayComplexName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        if chapter.displayTranslatedName.isEmpty == false {
                            Text(chapter.displayTranslatedName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.Token.deepEmerald.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let arabic = chapter.nameArabic, arabic.isEmpty == false {
                        Text(arabic)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.Token.deepEmerald)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .layoutPriority(1)
                            .environment(\.layoutDirection, .rightToLeft)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.Token.deepEmerald.opacity(0.05))
                            )
                    }
                }

                HStack(spacing: 8) {
                    ChapterRevelationBadge(chapter: chapter)

                    if let countLabel = chapter.versesCountLabel {
                        Text(countLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.Token.deepEmerald.opacity(0.1), Color.Token.softGrey.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(chapter.spokenAccessibilitySummary)
        .accessibilityHint("Open surah to read and listen")
    }
}
