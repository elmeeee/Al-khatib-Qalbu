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
    @ObservedObject private var languageManager = AppLanguageManager.shared

    let chapter: QuranChapter?
    var juzNumber: Int? = nil
    var initialVerseNumber: Int? = nil

    @AppStorage("chapterReaderFontScale") private var fontScale = 1.0
    @AppStorage("chapterReaderShowTranslation") private var showTranslation = true
    @AppStorage("chapterReaderShowTransliteration") private var showTransliteration = true
    @AppStorage("chapterReaderMemorizationMode") private var isMemorizationMode = false
    @AppStorage(ChapterReaderPreferences.translationIdKey) private var chapterTranslationId = ChapterReaderPreferences.defaultTranslationId

    @StateObject private var audio = AudioPlayerController()
    @State private var readerCoordinator: ChapterReaderCoordinator?
    @State private var vm: ChapterVersesViewModel?
    @State private var showReadingSettings = false
    @State private var isMenuExpanded = false
    @State private var showAISheet = false
    @State private var showNoteSheet = false
    @State private var toastMessage: String? = nil

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
            mainContent(chromeInsets: chromeInsets)
        }
        .id(languageManager.currentLanguage)
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
                TafsirReaderSheet(presenter: presenter)
            }
        }
        .sheet(isPresented: hadithSheetBinding) {
            if let presenter = readerCoordinator?.hadithPresenter {
                HadithReaderSheet(presenter: presenter)
            }
        }
        .sheet(isPresented: $showAISheet) {
            if let vm, let verse = readerCoordinator?.currentVerse(in: vm) {
                VerseAISheet(
                    surahName: currentSurahName,
                    verseNumber: verse.resolvedVerseNumber ?? 1,
                    verseText: verse.displayText ?? verse.textUthmani ?? "",
                    translationText: verse.translations?.first?.text ?? ""
                )
            }
        }
        .sheet(isPresented: $showNoteSheet) {
            if let vm, let verse = readerCoordinator?.currentVerse(in: vm), let key = verse.verseKey {
                VerseNoteSheet(
                    surahName: currentSurahName,
                    verseNumber: verse.resolvedVerseNumber ?? 1,
                    verseKey: key,
                    onSave: {
                        showToast(languageManager.currentLanguage == .english ? "Note saved" : "Catatan disimpan")
                    }
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

    @ViewBuilder
    private func mainContent(chromeInsets: ChapterReaderChromeInsets) -> some View {
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

            if isMenuExpanded {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(20)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isMenuExpanded = false
                        }
                    }
            }

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
                .zIndex(30)
            }

            if let toast = toastMessage {
                VStack {
                    Text(toast)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.Token.deepEmerald.opacity(0.95)))
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    Spacer()
                }
                .padding(.top, 100)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
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

    private var reloadingOverlay: some View {
        Color.black.opacity(0.35)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 12) {
                    ProgressView().tint(.white)
                    Text(AppLanguageManager.shared.localize("loading"))
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
        guard let vm else { return "" }

        if let currentVerse = readerCoordinator?.currentVerse(in: vm) {
            let verseNum = currentVerse.resolvedVerseNumber
            let label = languageManager.currentLanguage == .english ? "Verse" : "Ayah"
            if let verseNum {
                if let juz = currentVerse.juzNumber {
                    return "\(label) (\(verseNum)) • \(languageManager.localize("juz")) \(juz)"
                }
                return "\(label) \(verseNum)"
            }
        }

        if let firstVerse = vm.verses.first,
           let verseNum = firstVerse.resolvedVerseNumber {
            let label = languageManager.currentLanguage == .english ? "Verse" : "Ayah"
            if let juz = firstVerse.juzNumber {
                return "\(label) (\(verseNum)) • \(languageManager.localize("juz")) \(juz)"
            }
            return "\(label) \(verseNum)"
        }

        return readerCoordinator?.positionLabel(in: vm) ?? ""
    }

    private var chapterHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            headerIconButton(systemName: "chevron.left") {
                audio.stop()
                dismiss()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(currentSurahName)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color.Token.offWhite)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if currentPositionLabel.isEmpty == false {
                    Text(currentPositionLabel)
                        .font(.caption)
                        .foregroundColor(Color.Token.goldBright.opacity(0.85))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            headerIconButton(systemName: "gearshape.fill") {
                showReadingSettings = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .safeAreaPadding(.top, 4)
        .background(Color.Token.readerForest.opacity(0.92))
    }

    private func headerIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        let label = systemName == "chevron.left"
            ? AlKhatibAccessibility.Reader.back
            : AlKhatibAccessibility.Reader.settings
        let hint = systemName == "gearshape.fill" ? AlKhatibAccessibility.Reader.settingsHint : nil
        return Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.08)))
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .alKhatibAccessibility(label: label, hint: hint)
    }

    private var sideActionButtons: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 16) {
                if isMenuExpanded {
                    // Menu Items (vertical list)
                    fabMenuItem(icon: "bookmark.fill", color: Color.Token.goldBright, label: languageManager.currentLanguage == .english ? "Bookmark" : "Bookmark") {
                        if let vm, let verse = readerCoordinator?.currentVerse(in: vm), let key = verse.verseKey {
                            let bookmarked = UserDefaults.standard.stringArray(forKey: "bookmarked_verses") ?? []
                            var newBookmarks = bookmarked
                            if bookmarked.contains(key) {
                                newBookmarks.removeAll(where: { $0 == key })
                                showToast(languageManager.currentLanguage == .english ? "Removed bookmark" : "Bookmark dihapus")
                            } else {
                                newBookmarks.append(key)
                                showToast(languageManager.currentLanguage == .english ? "Bookmarked successfully" : "Bookmark disimpan")
                            }
                            UserDefaults.standard.set(newBookmarks, forKey: "bookmarked_verses")
                        }
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)), removal: .scale.combined(with: .opacity)))

                    fabMenuItem(icon: "pencil.and.outline", color: Color.Token.teal, label: languageManager.currentLanguage == .english ? "Notes" : "Catatan") {
                        showNoteSheet = true
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)), removal: .scale.combined(with: .opacity)))

                    fabMenuItem(icon: "brain.headlight", color: .orange, label: languageManager.currentLanguage == .english ? "Memorize" : "Tandai Hafalan") {
                        if let vm, let verse = readerCoordinator?.currentVerse(in: vm), let key = verse.verseKey {
                            let memorized = UserDefaults.standard.stringArray(forKey: "memorized_verses") ?? []
                            var newMemorized = memorized
                            if memorized.contains(key) {
                                newMemorized.removeAll(where: { $0 == key })
                                showToast(languageManager.currentLanguage == .english ? "Removed from memorized" : "Hafalan dibatalkan")
                            } else {
                                newMemorized.append(key)
                                showToast(languageManager.currentLanguage == .english ? "Marked as memorized" : "Telah dihafal")
                            }
                            UserDefaults.standard.set(newMemorized, forKey: "memorized_verses")
                        }
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)), removal: .scale.combined(with: .opacity)))

                    fabMenuItem(icon: "sparkles", color: .purple, label: "Tafsir AI") {
                        showAISheet = true
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)), removal: .scale.combined(with: .opacity)))

                    fabMenuItem(icon: "book.closed.fill", color: Color.Token.deepEmerald, label: "Tafsir") {
                        guard let readerCoordinator, let vm else { return }
                        readerCoordinator.openTafsirForCurrentAyah(in: vm)
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)), removal: .scale.combined(with: .opacity)))

                    fabMenuItem(icon: "text.book.closed.fill", color: Color.Token.indigoAccent, label: "Hadits") {
                        guard let readerCoordinator, let vm else { return }
                        readerCoordinator.openHadithForCurrentAyah(in: vm)
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)), removal: .scale.combined(with: .opacity)))
                }

                // Play/Pause button shown above collapsed FAB button
                if !isMenuExpanded, let vm, let readerCoordinator = readerCoordinator {
                    Button(action: {
                        if audio.isPlaying {
                            audio.pause()
                        } else {
                            if audio.currentURL != nil {
                                audio.toggle()
                            } else {
                                Task {
                                    await readerCoordinator.playEntireSurah(vm: vm)
                                }
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.Token.deepEmerald)
                                .frame(width: 48, height: 48)
                                .shadow(color: Color.Token.deepEmerald.opacity(0.3), radius: 6, y: 3)
                            
                            Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.opacity)
                }

                // Main FAB Button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isMenuExpanded.toggle()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.Token.deepEmerald, Color.Token.tealDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.Token.deepEmerald.opacity(0.4), radius: 8, x: 0, y: 4)

                        Image(systemName: isMenuExpanded ? "xmark" : "doc.text.image.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(isMenuExpanded ? 90 : 0))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func fabMenuItem(icon: String, color: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isMenuExpanded = false
            }
            action()
        }) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.65))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 44, height: 44)
                        .shadow(color: color.opacity(0.3), radius: 6, y: 3)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeOut(duration: 0.35)) {
                if toastMessage == message {
                    toastMessage = nil
                }
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
                                showTransliteration: showTransliteration,
                                isMemorizationMode: isMemorizationMode,
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
            .ignoresSafeArea()
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
