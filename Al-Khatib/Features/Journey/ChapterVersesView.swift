//
//  ChapterVersesView.swift
//  Al-Khatib
//

import SwiftUI

struct ChapterVersesView: View {
    @Environment(\.appContainer) private var container
    let chapter: QuranChapter

    @State private var vm: ChapterVersesViewModel?
    @StateObject private var audio = AudioPlayerController()

    var body: some View {
        ZStack {
            Color.Theme.offWhite.ignoresSafeArea()

            if let vm {
                versesContent(vm)
            } else {
                LoadingSkeleton()
            }
        }
        .navigationTitle(chapter.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if audio.currentURL != nil {
                chapterAudioBar
            }
        }
        .task {
            guard let c = container, vm == nil else { return }
            let model = ChapterVersesViewModel(chapter: chapter, content: c.content)
            vm = model
            await model.loadInitial()
        }
        .onDisappear {
            audio.stop()
        }
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
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.Theme.softGrey.opacity(0.35))
                        .frame(height: 220)
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
            LazyVStack(spacing: 16) {
                chapterHeader

                ForEach(bindable.verses, id: \.listIdentity) { verse in
                    AyahVerseCard(verse: verse, showsVerseLabel: false) {
                        if let url = verse.audio?.url {
                            audio.play(from: url, reciterName: "")
                        }
                    }
                    .onAppear {
                        Task { await bindable.loadMoreIfNeeded(currentVerse: verse) }
                    }
                }

                if bindable.isLoadingMore {
                    ProgressView()
                        .tint(Color.Theme.deepEmerald)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .refreshable {
            await bindable.loadInitial()
        }
    }

    private var chapterHeader: some View {
        VStack(spacing: 8) {
            if let arabic = chapter.nameArabic, arabic.isEmpty == false {
                Text(arabic)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(Color.Theme.deepEmerald)
                    .environment(\.layoutDirection, .rightToLeft)
            }

            Text(chapter.displayComplexName)
                .font(.title3.bold())
                .foregroundColor(.primary)

            if chapter.displayTranslatedName.isEmpty == false {
                Text(chapter.displayTranslatedName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color.Theme.deepEmerald)
            }

            if let countLabel = chapter.versesCountLabel {
                Text(countLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var chapterAudioBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform")
                .foregroundColor(Color.Theme.gold)
            Text("Playing recitation")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button { audio.toggle() } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
            }
            Button { audio.stop() } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}
