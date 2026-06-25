//
//  ChapterVersesView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ChapterVersesView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.dismiss) private var dismiss

    let chapter: QuranChapter?
    var juzNumber: Int? = nil
    var initialVerseNumber: Int? = nil

    @AppStorage("chapterReaderFontScale") private var fontScale = 1.0
    @AppStorage("chapterReaderShowTranslation") private var showTranslation = true
    @AppStorage(ChapterReaderPreferences.translationIdKey) private var chapterTranslationId = ChapterReaderPreferences.defaultTranslationId

    @StateObject private var audio = AudioPlayerController()
    @State private var readerCoordinator: ChapterReaderCoordinator?
    @State private var vm: ChapterVersesViewModel?
    @State private var showReadingSettings = false

    private var showsNowPlaying: Bool { audio.currentURL != nil }

    private var readerChromeShowsNowPlaying: Bool {
        showsNowPlaying || (readerCoordinator?.reservesReaderChromeForAudio == true)
    }

    private var floatingPlayerBottomPadding: CGFloat {
        TabBarLayout.spacingAboveTabBar + TabBarLayout.nowPlayingBottomPadding
    }

    private var floatingActionsBottomPadding: CGFloat {
        let base: CGFloat = 72
        if readerChromeShowsNowPlaying {
            return base + TabBarLayout.nowPlayingChromeHeight + 12
        }
        return base
    }

    var body: some View {
        GeometryReader { rootGeo in
            let chromeInsets = ChapterReaderChromeInsets.resolved(
                safeArea: rootGeo.safeAreaInsets,
                showsNowPlaying: readerChromeShowsNowPlaying
            )

            ZStack {
                Group {
                    if let vm {
                        versePager(vm)
                    } else {
                        ChapterReaderBackground()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environment(\.chapterReaderChromeInsets, chromeInsets)

                VStack(spacing: 0) {
                    chapterHeader
                    Spacer()
                }

                VStack(spacing: 0) {
                    Spacer()
                    if showsNowPlaying {
                        floatingNowPlayingBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .safeAreaPadding(.horizontal)
                .safeAreaPadding(.bottom, floatingPlayerBottomPadding)

                if readerCoordinator?.isOnIntroPage == false {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            sideActionButtons
                        }
                    }
                    .padding(.trailing, 12)
                    .safeAreaPadding(.bottom, floatingActionsBottomPadding)
                }

                if vm == nil || (vm?.isLoading == true && vm?.verses.isEmpty == true) {
                    ProgressView()
                        .tint(.white)
                        .allowsHitTesting(false)
                }

                if let vm, vm.isLoadingMore {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .safeAreaPadding(.bottom, floatingActionsBottomPadding)
                        .allowsHitTesting(false)
                }

                if let vm, vm.isReloadingContent {
                    reloadingOverlay
                }
            }
        }
        .chapterReaderScreenBackground()
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if readerCoordinator == nil {
                readerCoordinator = ChapterReaderCoordinator(chapter: chapter, juzNumber: juzNumber, audio: audio)
            }
        }
        .task {
            guard let container, vm == nil, let readerCoordinator else { return }
            let model = readerCoordinator.bootstrap(container: container)
            vm = model
            await model.loadInitial()
            readerCoordinator.applyInitialScrollIfNeeded(vm: model, initialVerseNumber: initialVerseNumber)
            readerCoordinator.lastAppliedTranslationId = chapterTranslationId
        }
        .onChange(of: chapterTranslationId) { _, newId in
            guard let readerCoordinator, readerCoordinator.lastAppliedTranslationId != newId else { return }
            readerCoordinator.lastAppliedTranslationId = newId
            guard let vm else { return }
            audio.stop()
            Task { await vm.applyContentPreferencesChange() }
        }
        .onReceive(NotificationCenter.default.publisher(for: ChapterReaderPreferences.translationDidChangeNotification)) { _ in
            let selected = ChapterReaderPreferences.selectedTranslationId()
            guard let readerCoordinator, readerCoordinator.lastAppliedTranslationId != selected else { return }
            readerCoordinator.lastAppliedTranslationId = selected
            guard let vm else { return }
            audio.stop()
            Task { await vm.applyContentPreferencesChange() }
        }
        .sheet(isPresented: $showReadingSettings) {
            if let vm {
                ChapterReadingSettingsSheetContent(
                    viewModel: vm,
                    fontScale: $fontScale,
                    showTranslation: $showTranslation,
                    onPreferencesChange: {
                        audio.stop()
                        Task { await vm.applyContentPreferencesChange() }
                    }
                )
            }
        }
        .sheet(isPresented: tafsirSheetBinding) {
            if let presenter = readerCoordinator?.tafsirPresenter {
                TafsirReaderSheet(
                    verseReference: presenter.verseReference,
                    commentarySource: presenter.commentarySource,
                    isLoading: presenter.isLoading,
                    loadErrorDescription: presenter.loadErrorDescription,
                    commentaryUnavailable: presenter.commentaryUnavailable,
                    htmlFragment: presenter.htmlFragment,
                    reload: { Task { await presenter.reload() } }
                )
            }
        }
        .sheet(isPresented: hadithSheetBinding) {
            if let presenter = readerCoordinator?.hadithPresenter {
                HadithReaderSheet(
                    verseReference: presenter.verseReference,
                    items: presenter.items,
                    isLoading: presenter.isLoading,
                    isLoadingMore: presenter.isLoadingMore,
                    hasMore: presenter.hasMore,
                    loadErrorDescription: presenter.loadErrorDescription,
                    contentUnavailable: presenter.contentUnavailable,
                    reload: { Task { await presenter.reload() } },
                    loadMore: { Task { await presenter.loadMore() } }
                )
            }
        }
        .onChange(of: audio.activeSequenceIndex) { _, _ in
            guard let vm, let readerCoordinator else { return }
            readerCoordinator.onActiveSequenceIndexChanged(vm: vm)
        }
        .onChange(of: audio.currentURL) { _, url in
            guard let vm, let readerCoordinator else { return }
            readerCoordinator.onAudioURLChanged(url, vm: vm)
        }
        .onDisappear {
            readerCoordinator?.onDisappear()
        }
    }

    private var reloadingOverlay: some View {
        Color.black.opacity(0.35)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 12) {
                    ProgressView().tint(.white)
                    Text("Updating verses…")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .allowsHitTesting(true)
    }

    private var currentSurahName: String {
        if let vm,
           let currentVerse = readerCoordinator?.currentVerse(in: vm),
           let chapterNum = currentVerse.chapterNumber,
           let name = vm.chapterLookup[chapterNum] {
            return name
        }
        return chapter?.displayComplexName ?? vm?.surahDisplayTitle ?? ""
    }

    private var currentPositionLabel: String {
        if let vm,
           let currentVerse = readerCoordinator?.currentVerse(in: vm) {
            let verseNum = currentVerse.resolvedVerseNumber
            if let juz = currentVerse.juzNumber {
                return "Ayah \(verseNum) · Juz \(juz)"
            }
            return "Ayah \(verseNum)"
        }
        return readerCoordinator?.positionLabel(in: vm) ?? chapter?.versesCountLabel ?? ""
    }

    private var chapterHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            headerIconButton(systemName: "chevron.left") {
                audio.stop()
                dismiss()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(currentSurahName)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color.Token.slate900)
                    .lineLimit(1)

                Text(currentPositionLabel)
                    .font(.caption)
                    .foregroundColor(Color.Token.slate500)
            }

            Spacer(minLength: 8)

            headerIconButton(systemName: "gearshape.fill") {
                showReadingSettings = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .safeAreaPadding(.top, 4)
        .background(Color.Token.screenBackground.opacity(0.95))
    }

    private func headerIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        let label = systemName == "chevron.left"
            ? AlKhatibAccessibility.Reader.back
            : AlKhatibAccessibility.Reader.settings
        let hint = systemName == "gearshape.fill" ? AlKhatibAccessibility.Reader.settingsHint : nil
        return Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.Token.slate900)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.Token.lightGrey))
        }
        .alKhatibAccessibility(label: label, hint: hint)
    }

    private var sideActionButtons: some View {
        VStack(spacing: 18) {
            QFSideActionButton(icon: "text.book.closed.fill", label: "Hadith") {
                guard let readerCoordinator, let vm else { return }
                readerCoordinator.openHadithForCurrentAyah(in: vm)
            }
            QFSideActionButton(icon: "book.closed.fill", label: "Tafsir") {
                guard let readerCoordinator, let vm else { return }
                readerCoordinator.openTafsirForCurrentAyah(in: vm)
            }
        }
    }

    private var floatingNowPlayingBar: some View {
        ChapterNowPlayingBar(audio: audio)
            .padding(.horizontal, TabBarLayout.nowPlayingHorizontalInset)
            .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    }

    private var tafsirSheetBinding: Binding<Bool> {
        Binding(
            get: { readerCoordinator?.tafsirPresenter?.isSheetPresented ?? false },
            set: { readerCoordinator?.tafsirPresenter?.isSheetPresented = $0 }
        )
    }

    private var hadithSheetBinding: Binding<Bool> {
        Binding(
            get: { readerCoordinator?.hadithPresenter?.isSheetPresented ?? false },
            set: { readerCoordinator?.hadithPresenter?.isSheetPresented = $0 }
        )
    }

    @ViewBuilder
    private func versePager(_ vm: ChapterVersesViewModel) -> some View {
        @Bindable var bindable = vm

        if bindable.isLoading && bindable.verses.isEmpty {
            ChapterReaderBackground()
        } else if let error = bindable.errorMessage, bindable.verses.isEmpty {
            errorOverlay(error) {
                Task { await bindable.loadInitial() }
            }
        } else if bindable.verses.isEmpty {
            Text("No verses found")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let readerCoordinator {
            @Bindable var readerCoordinator = readerCoordinator
            GeometryReader { pagerGeo in
                let pageHeight = pagerGeo.size.height

                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        if let ch = chapter {
                            ChapterIntroPage(
                                chapter: ch,
                                isPreparingPlayAll: bindable.isPreparingPlayAll,
                                onPlayAll: { Task { await readerCoordinator.playEntireSurah(vm: bindable) } },
                                onTapScreen: { Task { await readerCoordinator.playEntireSurah(vm: bindable) } }
                            )
                            .frame(width: pagerGeo.size.width, height: pageHeight)
                            .clipped()
                            .id(ChapterReaderCoordinator.ScrollID.intro)
                        }

                        ForEach(bindable.verses, id: \.listIdentity) { verse in
                            ChapterAyahPage(
                                verse: verse,
                                showTranslation: showTranslation,
                                fontScale: fontScale,
                                isPlaying: audio.isPlayingURL(verse.audio?.url) && audio.isPlaying,
                                onTapScreen: { readerCoordinator.handleTap(for: verse, vm: bindable) }
                            )
                            .frame(width: pagerGeo.size.width, height: pageHeight)
                            .clipped()
                            .id(verse.listIdentity)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                .scrollPosition(id: $readerCoordinator.scrollPosition, anchor: .top)
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
            }
            .ignoresSafeArea(edges: .top)
            .onChange(of: readerCoordinator.scrollPosition) { _, newID in
                readerCoordinator.onScrollPositionChanged(newID, vm: bindable)
            }
        }
    }

    private func errorOverlay(_ message: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(Color.Token.deepEmerald)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
