//
//  AudioPlayerViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

struct AudioQueueItem: Sendable, Equatable {
    let url: String
    let subtitle: String
}

@MainActor
final class AudioPlayerController: ObservableObject {
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var reciterName: String = ""
    @Published var trackTitle: String = ""
    @Published var trackSubtitle: String = ""
    @Published var currentURL: String?

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var queue: [AudioQueueItem] = []
    private var queueIndex = 0

    func play(from urlString: String, reciterName: String) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        let finalURLStr = AppEndpoints.URLBuilder.absoluteVerseMediaURLString(from: urlString)
        guard let url = URL(string: finalURLStr) else {
            return
        }
        self.reciterName = reciterName
        let shouldCreateNewItem = (currentURL != finalURLStr) || (player == nil)
        currentURL = finalURLStr
        if shouldCreateNewItem {
            removeObserver()
            player = AVPlayer(url: url)
            addObserver()
        }
        player?.play()
        isPlaying = true
    }

    func playVerse(
        url: String,
        surahTitle: String,
        ayahLabel: String,
        reciterName: String
    ) {
        queue = []
        queueIndex = 0
        trackTitle = surahTitle
        trackSubtitle = ayahLabel
        play(from: url, reciterName: reciterName)
    }

    func playSequence(
        items: [AudioQueueItem],
        surahTitle: String,
        reciterName: String,
        startIndex: Int = 0
    ) {
        guard items.isEmpty == false else { return }
        queue = items
        queueIndex = min(max(startIndex, 0), items.count - 1)
        trackTitle = surahTitle
        self.reciterName = reciterName
        playCurrentQueueItem()
    }

    func isPlayingURL(_ urlString: String?) -> Bool {
        guard let urlString, let currentURL else { return false }
        let normalized = AppEndpoints.URLBuilder.absoluteVerseMediaURLString(from: urlString)
        return normalized == currentURL
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func toggle() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        progress = 0
        currentURL = nil
        queue = []
        queueIndex = 0
        trackTitle = ""
        trackSubtitle = ""
        removeObserver()
    }

    func seekToProgress(_ value: Double) {
        guard let player, let item = player.currentItem else { return }
        let duration = item.duration.seconds
        guard duration.isFinite, duration > 0 else { return }
        let seconds = duration * value
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: time)
    }

    private func playCurrentQueueItem() {
        guard queue.indices.contains(queueIndex) else { return }
        let item = queue[queueIndex]
        trackSubtitle = item.subtitle
        play(from: item.url, reciterName: reciterName)
    }

    private func handlePlaybackEnded() {
        if queueIndex + 1 < queue.count {
            queueIndex += 1
            playCurrentQueueItem()
        } else {
            queue = []
            queueIndex = 0
            stop()
        }
    }

    private func addObserver() {
        guard let player else { return }
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            let current = time.seconds
            let duration = player.currentItem?.duration.seconds ?? 0
            Task { @MainActor [weak self] in
                guard let self else { return }
                await Task.yield()
                if duration.isFinite, duration > 0 {
                    self.progress = current / duration
                } else {
                    self.progress = 0
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handlePlaybackEnded()
            }
        }
    }

    private func removeObserver() {
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }
}
