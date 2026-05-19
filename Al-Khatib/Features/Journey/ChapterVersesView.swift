//
//  ChapterVersesView.swift
//  Al-Khatib
//

import SwiftUI

struct ChapterVersesView: View {
    @Environment(\.appContainer) private var container
    let chapter: QuranChapter

    @State private var vm: ChapterVersesViewModel?
    @State private var tafsirPresenter: TafsirPresenter?
    @StateObject private var audio = AudioPlayerController()

    var body: some View {
        ZStack {
            chapterBackground

            if let vm {
                versesContent(vm)
            } else {
                LoadingSkeleton()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if audio.currentURL != nil {
                VerseAudioBar(audio: audio)
            }
        }
        .task {
            guard let c = container, vm == nil else { return }
            let model = ChapterVersesViewModel(chapter: chapter, content: c.content)
            vm = model
            if tafsirPresenter == nil {
                tafsirPresenter = TafsirPresenter(content: c.content)
            }
            await model.loadInitial()
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
        .onDisappear {
            audio.stop()
        }
    }

    private var chapterBackground: some View {
        LinearGradient(
            colors: [Color.Theme.offWhite, Color(hex: "#F0F4F1"), Color.Theme.offWhite],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var tafsirSheetBinding: Binding<Bool> {
        Binding(
            get: { tafsirPresenter?.isSheetPresented ?? false },
            set: { tafsirPresenter?.isSheetPresented = $0 }
        )
    }

    @ViewBuilder
    private func versesContent(_ vm: ChapterVersesViewModel) -> some View {
        @Bindable var bindable = vm

        if bindable.isLoading && bindable.verses.isEmpty {
            versesLoadingBody
        } else if let error = bindable.errorMessage, bindable.verses.isEmpty {
            versesErrorBody(error) {
                Task { await bindable.loadInitial() }
            }
        } else if bindable.verses.isEmpty {
            versesEmptyBody
        } else {
            versesList(bindable)
        }
    }

    private var versesLoadingBody: some View {
        ScrollView {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.Theme.deepEmerald.opacity(0.12))
                    .frame(height: 160)
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.Theme.softGrey.opacity(0.35))
                        .frame(height: 200)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
        .redacted(reason: .placeholder)
    }

    private func versesErrorBody(_ message: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Spacer()
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

    private var versesEmptyBody: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("No verses found")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private func versesList(_ vm: ChapterVersesViewModel) -> some View {
        @Bindable var bindable = vm

        return ScrollView {
            LazyVStack(spacing: 0) {
                chapterHero(bindable)
                    .padding(.bottom, 20)

                LazyVStack(spacing: 16) {
                    ForEach(bindable.verses, id: \.listIdentity) { verse in
                        ChapterAyahCard(
                            verse: verse,
                            ayahNumber: verse.verseNumber,
                            isPlaying: audio.isPlayingURL(verse.audio?.url),
                            onPlay: { playSingleAyah(verse, vm: bindable) },
                            onTafsir: { tafsirPresenter?.open(for: verse) }
                        )
                        .onAppear {
                            if let key = verse.verseKey {
                                Task { await tafsirPresenter?.prefetch(ayahKey: key) }
                            }
                            Task { await bindable.loadMoreIfNeeded(currentVerse: verse) }
                        }
                    }

                    if bindable.isLoadingMore {
                        ProgressView()
                            .tint(Color.Theme.deepEmerald)
                            .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, audio.currentURL == nil ? 32 : 88)
            }
        }
        .refreshable {
            await bindable.loadInitial()
        }
    }

    private func chapterHero(_ vm: ChapterVersesViewModel) -> some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    Color.Theme.deepEmerald,
                    Color(hex: "#0A3D2E"),
                    Color.Theme.deepEmerald.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                Circle()
                    .fill(Color.Theme.gold.opacity(0.08))
                    .frame(width: geo.size.width * 0.7)
                    .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.2)
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.1)
            }

            VStack(spacing: 14) {
                HStack {
                    Button { dismissChapter() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                if let arabic = chapter.nameArabic, arabic.isEmpty == false {
                    Text(arabic)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                        .environment(\.layoutDirection, .rightToLeft)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }

                Text(chapter.displayComplexName)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                if chapter.displayTranslatedName.isEmpty == false {
                    Text(chapter.displayTranslatedName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color.Theme.gold.opacity(0.95))
                }

                if let countLabel = chapter.versesCountLabel {
                    Text(countLabel)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.75))
                }

                playAllButton(vm)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
        )
    }

    private func playAllButton(_ vm: ChapterVersesViewModel) -> some View {
        Button {
            Task { await playEntireSurah(vm: vm) }
        } label: {
            HStack(spacing: 10) {
                if vm.isPreparingPlayAll {
                    ProgressView()
                        .tint(Color.Theme.deepEmerald)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                }
                Text(vm.isPreparingPlayAll ? "Loading..." : "Play Surah")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(Color.Theme.deepEmerald)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.Theme.pureWhite))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(vm.isPreparingPlayAll)
    }

    @Environment(\.dismiss) private var dismiss

    private func dismissChapter() {
        audio.stop()
        dismiss()
    }

    @MainActor
    private func playSingleAyah(_ verse: RandomAyahPayload, vm: ChapterVersesViewModel) {
        guard let url = verse.audio?.url else { return }
        let reciter = vm.reciterDisplayName
        let ayah = vm.ayahSubtitle(for: verse)
        audio.playVerse(
            url: url,
            surahTitle: vm.surahDisplayTitle,
            ayahSubtitle: "\(ayah) — \(reciter)",
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

        let reciter = vm.reciterDisplayName
        audio.playSequence(
            items: items,
            surahTitle: vm.surahDisplayTitle,
            reciterName: reciter,
            startIndex: 0
        )
    }
}
