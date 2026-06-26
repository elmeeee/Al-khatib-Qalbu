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
    @State private var selectedTab: Int = 0
    @ObservedObject private var languageManager = AppLanguageManager.shared

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
                    juzNumber: route.juzNumber,
                    initialVerseNumber: route.initialVerseNumber
                )
                .toolbar(.hidden, for: .tabBar)
                .toolbarBackground(.hidden, for: .navigationBar)
            }
        }
        .id(languageManager.currentLanguage)
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
            
            HStack(spacing: 4) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 0
                    }
                }) {
                    Text(languageManager.localize("surah"))
                        .font(.system(size: 14, weight: selectedTab == 0 ? .bold : .medium))
                        .foregroundColor(selectedTab == 0 ? .white : Color.Token.slate600)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedTab == 0 {
                                    LinearGradient(
                                        colors: [Color.Token.deepEmerald, Color.Token.tealDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .cornerRadius(20)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 1
                    }
                }) {
                    Text(languageManager.localize("juz"))
                        .font(.system(size: 14, weight: selectedTab == 1 ? .bold : .medium))
                        .foregroundColor(selectedTab == 1 ? .white : Color.Token.slate600)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedTab == 1 {
                                    LinearGradient(
                                        colors: [Color.Token.deepEmerald, Color.Token.tealDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .cornerRadius(20)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(4)
            .background(
                LinearGradient(
                    colors: [Color.Token.lightGrey.opacity(0.8), Color.Token.sageMist.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(24)
            .padding(.horizontal)
            .padding(.bottom, 12)

            if selectedTab == 0 {
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
            } else {
                if bindable.isLoadingJuzs && bindable.juzs.isEmpty {
                    chaptersLoadingBody
                } else if let error = bindable.errorMessageJuzs, bindable.juzs.isEmpty {
                    chaptersErrorBody(error) {
                        Task { await bindable.refreshAll(force: true) }
                    }
                } else if bindable.juzs.isEmpty {
                    chaptersEmptyBody
                } else {
                    juzsList(bindable)
                }
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
                    Text(languageManager.localize("quran_title"))
                        .font(.largeTitle.bold())
                        .foregroundColor(Color.Token.deepEmerald)
                }
            }

            Text(selectedTab == 0 ? languageManager.localize("quran_subtitle") : languageManager.localize("quran_subtitle_juz"))
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
            Button(languageManager.localize("try_again"), action: retry)
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
            Text(languageManager.localize("no_chapters"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private func chaptersList(_ vm: QuranChaptersViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let route = vm.continueReadingRoute(), let ch = route.chapter {
                    NavigationLink(value: route) {
                        ContinueReadingCard(
                            chapter: ch,
                            verseNumber: route.initialVerseNumber ?? 1
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 16)
                }

                ForEach(Array(vm.chapters.enumerated()), id: \.element.id) { index, chapter in
                    VStack(spacing: 0) {
                        NavigationLink(value: ChapterReaderRoute(chapter: chapter, juzNumber: nil, initialVerseNumber: nil)) {
                            QuranChapterRow(chapter: chapter)
                        }
                        .buttonStyle(.plain)
                        
                        if index < vm.chapters.count - 1 {
                            Divider()
                                .opacity(0.3)
                                .padding(.leading, 56)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .refreshable {
            await vm.refreshAll(force: true)
        }
    }

    private func juzsList(_ vm: QuranChaptersViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(vm.juzs.enumerated()), id: \.element.id) { index, juz in
                    let start = juz.startChapterAndAyah()
                    let chapter = start.flatMap { chAndAyah in vm.chapters.first(where: { $0.id == chAndAyah.0 }) }
                    
                    VStack(spacing: 0) {
                        NavigationLink(value: ChapterReaderRoute(chapter: nil, juzNumber: juz.juzNumber, initialVerseNumber: start?.1)) {
                            JuzRow(juz: juz, chapter: chapter)
                        }
                        .buttonStyle(.plain)
                        
                        if index < vm.juzs.count - 1 {
                            Divider()
                                .opacity(0.3)
                                .padding(.leading, 56)
                        }
                    }
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
                Text(AppLanguageManager.shared.localize("continue_reading"))
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
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.Token.deepEmerald, Color.Token.tealDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Text("\(chapter.id)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(chapter.displayComplexName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        if chapter.displayTranslatedName.isEmpty == false {
                            Text(chapter.displayTranslatedName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
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
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.Token.deepEmerald.opacity(0.06))
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
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(chapter.spokenAccessibilitySummary)
        .accessibilityHint("Open surah to read and listen")
    }
}

private struct JuzRow: View {
    let juz: QuranJuz
    let chapter: QuranChapter?

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.Token.gold, Color.Token.goldDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Text("\(juz.juzNumber)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Juz \(juz.juzNumber)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        if let start = juz.startChapterAndAyah() {
                            let surahName = chapter?.displayComplexName ?? "Surah \(start.0)"
                            Text("\(AppLanguageManager.shared.localize("starts_at")) \(surahName) \u{2022} Ayah \(start.1)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let count = juz.versesCount {
                    Text("\(count) \(AppLanguageManager.shared.localize("verses"))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
