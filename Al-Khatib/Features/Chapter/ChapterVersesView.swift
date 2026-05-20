//
//  ChapterVersesView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ChapterVersesView: View {
    private enum ScrollID {
        static let intro = "chapter-intro"
    }

    @Environment(\.appContainer) private var container
    @Environment(\.dismiss) private var dismiss
    let chapter: QuranChapter
    var initialVerseNumber: Int? = nil

    @AppStorage("chapterReaderFontScale") private var fontScale = 1.0
    @AppStorage("chapterReaderShowTranslation") private var showTranslation = true

    @State private var vm: ChapterVersesViewModel?
    @State private var tafsirPresenter: TafsirPresenter?
    @State private var hadithPresenter: HadithPresenter?
    @StateObject private var audio = AudioPlayerController()
    @State private var scrollPosition: String? = ScrollID.intro
    @State private var showReadingSettings = false
    @State private var readingTracker: ReadingSessionTracker?
    @State private var reservesReaderChromeForAudio = false

    private var isOnIntroPage: Bool {
        scrollPosition == ScrollID.intro || scrollPosition == nil
    }

    private var showsLoadingContent: Bool {
        vm == nil || (vm?.isLoading == true && vm?.verses.isEmpty == true)
    }

    private var showsNowPlaying: Bool {
        audio.currentURL != nil
    }

    private var readerChromeShowsNowPlaying: Bool {
        showsNowPlaying || reservesReaderChromeForAudio
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

            if isOnIntroPage == false {
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

            if showsLoadingContent {
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
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("Updating verses…")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .allowsHitTesting(true)
            }
            }
        }
        .chapterReaderScreenBackground()
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard let c = container, vm == nil else { return }
            let model = ChapterVersesViewModel(chapter: chapter, content: c.content)
            vm = model
            if tafsirPresenter == nil {
                tafsirPresenter = TafsirPresenter(content: c.content)
            }
            if hadithPresenter == nil {
                hadithPresenter = HadithPresenter(content: c.content)
            }
            if readingTracker == nil {
                readingTracker = ReadingSessionTracker(
                    repository: c.readingSessions,
                    userSession: c.userSession
                )
            }
            await model.loadInitial()
            applyInitialScrollIfNeeded(vm: model)
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
            if let tafsirPresenter {
                TafsirReaderSheet(
                    verseReference: tafsirPresenter.verseReference,
                    commentarySource: tafsirPresenter.commentarySource,
                    isLoading: tafsirPresenter.isLoading,
                    loadErrorDescription: tafsirPresenter.loadErrorDescription,
                    commentaryUnavailable: tafsirPresenter.commentaryUnavailable,
                    htmlFragment: tafsirPresenter.htmlFragment,
                    reload: { Task { await tafsirPresenter.reload() } }
                )
            }
        }
        .sheet(isPresented: hadithSheetBinding) {
            if let hadithPresenter {
                HadithReaderSheet(
                    verseReference: hadithPresenter.verseReference,
                    items: hadithPresenter.items,
                    isLoading: hadithPresenter.isLoading,
                    isLoadingMore: hadithPresenter.isLoadingMore,
                    hasMore: hadithPresenter.hasMore,
                    loadErrorDescription: hadithPresenter.loadErrorDescription,
                    contentUnavailable: hadithPresenter.contentUnavailable,
                    reload: { Task { await hadithPresenter.reload() } },
                    loadMore: { Task { await hadithPresenter.loadMore() } }
                )
            }
        }
        .onChange(of: scrollPosition) { _, newID in
            guard let vm, let newID, newID != ScrollID.intro else { return }
            guard let verse = vm.verses.first(where: { $0.listIdentity == newID }) else { return }
            trackReadingSession(for: verse)
            Task {
                if let key = verse.verseKey {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await self.tafsirPresenter?.prefetch(ayahKey: key) }
                        group.addTask { await self.hadithPresenter?.prefetch(ayahKey: key) }
                    }
                }
                await vm.loadMoreIfNeeded(currentVerse: verse)
            }
        }
        .onChange(of: audio.activeSequenceIndex) { _, _ in
            guard let vm, audio.isPlayingSequence else { return }
            Task { @MainActor in
                await Task.yield()
                syncScrollToPlayingVerse(vm: vm)
            }
        }
        .onChange(of: audio.currentURL) { _, url in
            if url == nil {
                reservesReaderChromeForAudio = false
                return
            }
            guard let vm, audio.isPlayingSequence == false else { return }
            Task { @MainActor in
                await Task.yield()
                syncScrollToPlayingVerse(vm: vm)
            }
        }
        .onDisappear {
            reservesReaderChromeForAudio = false
            Task { await readingTracker?.flush() }
            audio.stop()
        }
    }

    private func trackReadingSession(for verse: RandomAyahPayload) {
        guard let verseNumber = verse.resolvedVerseNumber else { return }
        readingTracker?.updateVisibleAyah(chapterNumber: chapter.id, verseNumber: verseNumber)
    }

    private func applyInitialScrollIfNeeded(vm: ChapterVersesViewModel) {
        guard let target = initialVerseNumber, target >= 1 else { return }
        guard let verse = vm.verses.first(where: { $0.resolvedVerseNumber == target }) else {
            return
        }
        scrollToVerse(identity: verse.listIdentity)
    }

    @MainActor
    private func syncScrollToPlayingVerse(vm: ChapterVersesViewModel) {
        guard let verse = verseMatchingPlayback(in: vm) else { return }
        scrollToVerse(identity: verse.listIdentity)
    }

    private func verseMatchingPlayback(in vm: ChapterVersesViewModel) -> RandomAyahPayload? {
        if let index = audio.activeSequenceIndex,
           let item = audio.queueItem(at: index) {
            let target = AppEndpoints.URLBuilder.absoluteVerseMediaURLString(from: item.url)
            return vm.verses.first { verse in
                guard let url = verse.audio?.url else { return false }
                return AppEndpoints.URLBuilder.absoluteVerseMediaURLString(from: url) == target
            }
        }
        return vm.verses.first { audio.isPlayingURL($0.audio?.url) }
    }
    
    private func scrollToVerse(identity: String) {
        guard scrollPosition != identity else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            scrollPosition = identity
        }
        Task { @MainActor in
            await Task.yield()
            guard scrollPosition != identity else { return }
            var retry = Transaction()
            retry.disablesAnimations = true
            withTransaction(retry) {
                scrollPosition = identity
            }
        }
    }

    private var floatingNowPlayingBar: some View {
        ChapterNowPlayingBar(audio: audio)
            .padding(.horizontal, TabBarLayout.nowPlayingHorizontalInset)
            .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    }

    private var sideActionButtons: some View {
        VStack(spacing: 18) {
            QFSideActionButton(
                icon: "text.book.closed.fill",
                label: "Hadith",
                action: openHadithForCurrentAyah
            )
            QFSideActionButton(
                icon: "book.closed.fill",
                label: "Tafsir",
                action: openTafsirForCurrentAyah
            )
        }
    }

    private var chapterHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            headerIconButton(systemName: "chevron.left") {
                audio.stop()
                dismiss()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(chapter.displayComplexName)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(positionLabel)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.72))
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
    }

    private func headerIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.12)))
        }
    }

    private var tafsirSheetBinding: Binding<Bool> {
        Binding(
            get: { tafsirPresenter?.isSheetPresented ?? false },
            set: { tafsirPresenter?.isSheetPresented = $0 }
        )
    }

    private var hadithSheetBinding: Binding<Bool> {
        Binding(
            get: { hadithPresenter?.isSheetPresented ?? false },
            set: { hadithPresenter?.isSheetPresented = $0 }
        )
    }

    private var positionLabel: String {
        guard let vm, let scrollPosition, scrollPosition != ScrollID.intro else {
            return chapter.versesCountLabel ?? ""
        }
        if let index = vm.verses.firstIndex(where: { $0.listIdentity == scrollPosition }) {
            let total = chapter.versesCount ?? vm.verses.count
            return "Ayah \(index + 1) / \(total)"
        }
        return chapter.versesCountLabel ?? ""
    }

    private func openTafsirForCurrentAyah() {
        guard let verse = currentVerse else { return }
        tafsirPresenter?.open(for: verse)
    }

    private func openHadithForCurrentAyah() {
        guard let verse = currentVerse else { return }
        hadithPresenter?.open(for: verse)
    }

    private var currentVerse: RandomAyahPayload? {
        guard let vm,
              let scrollPosition,
              scrollPosition != ScrollID.intro else {
            return nil
        }
        return vm.verses.first(where: { $0.listIdentity == scrollPosition })
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
        } else {
            GeometryReader { pagerGeo in
                let pageHeight = pagerGeo.size.height

                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ChapterIntroPage(
                            chapter: chapter,
                            isPreparingPlayAll: bindable.isPreparingPlayAll,
                            onPlayAll: { Task { await playEntireSurah(vm: bindable) } },
                            onTapScreen: { Task { await playEntireSurah(vm: bindable) } }
                        )
                        .frame(width: pagerGeo.size.width, height: pageHeight)
                        .clipped()
                        .id(ScrollID.intro)

                        ForEach(bindable.verses, id: \.listIdentity) { verse in
                            ChapterAyahPage(
                                verse: verse,
                                showTranslation: showTranslation,
                                fontScale: fontScale,
                                isPlaying: audio.isPlayingURL(verse.audio?.url) && audio.isPlaying,
                                onTapScreen: { handleTap(for: verse, vm: bindable) }
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
                .scrollPosition(id: $scrollPosition, anchor: .top)
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
            }
            .ignoresSafeArea(edges: .top)
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
                .tint(Color.Theme.deepEmerald)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    private func handleTap(for verse: RandomAyahPayload, vm: ChapterVersesViewModel) {
        guard let url = verse.audio?.url else { return }
        let reciter = vm.reciterDisplayName
        let ayah = vm.ayahSubtitle(for: verse)

        if audio.isPlayingURL(url) {
            audio.toggle()
            return
        }

        scrollToVerse(identity: verse.listIdentity)

        audio.playVerse(
            url: url,
            surahTitle: vm.surahDisplayTitle,
            ayahLabel: ayah,
            reciterName: reciter
        )
    }

    @MainActor
    private func playEntireSurah(vm: ChapterVersesViewModel) async {
        vm.isPreparingPlayAll = true
        defer { vm.isPreparingPlayAll = false }

        await vm.ensureAllVersesLoaded()
        let items = vm.audioQueueItems()
        guard items.isEmpty == false else { return }

        reservesReaderChromeForAudio = true

        if let firstItem = items.first {
            let targetURL = AppEndpoints.URLBuilder.absoluteVerseMediaURLString(from: firstItem.url)
            if let first = vm.verses.first(where: { verse in
                guard let url = verse.audio?.url else { return false }
                return AppEndpoints.URLBuilder.absoluteVerseMediaURLString(from: url) == targetURL
            }) {
                scrollToVerse(identity: first.listIdentity)
                await Task.yield()
                try? await Task.sleep(nanoseconds: 80_000_000)
            }
        }

        let reciter = vm.reciterDisplayName
        audio.playSequence(
            items: items,
            surahTitle: vm.surahDisplayTitle,
            reciterName: reciter,
            startIndex: 0
        )
    }
}
