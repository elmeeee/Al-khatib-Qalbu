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
    @Published private(set) var activeSequenceIndex: Int?

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var queue: [AudioQueueItem] = []
    private var queueIndex = 0

    /// System Control Center / Lock Screen bridge
    private let nowPlayingBridge = NowPlayingBridge()

    /// Live Activity manager for Dynamic Island + Lock Screen
    private let liveActivity = LiveActivityManager()

    var isPlayingSequence: Bool {
        activeSequenceIndex != nil
    }

    // MARK: – Lifecycle

    init() {
        setupRemoteCommands()
    }

    // MARK: – Playback

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
        pushNowPlayingInfo(rate: 1.0)
    }

    func playVerse(
        url: String,
        surahTitle: String,
        ayahLabel: String,
        reciterName: String
    ) {
        queue = []
        queueIndex = 0
        activeSequenceIndex = nil
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
        activeSequenceIndex = queueIndex
        trackTitle = surahTitle
        self.reciterName = reciterName
        playCurrentQueueItem()

        // Start Live Activity
        let verseLabel = queue[queueIndex].subtitle
        liveActivity.startActivity(
            surahName: surahTitle,
            reciterName: reciterName,
            verseLabel: verseLabel,
            currentVerse: queueIndex + 1,
            totalVerses: queue.count
        )
    }

    func isPlayingURL(_ urlString: String?) -> Bool {
        guard let urlString, let currentURL else { return false }
        let normalized = AppEndpoints.URLBuilder.absoluteVerseMediaURLString(from: urlString)
        return normalized == currentURL
    }

    func pause() {
        player?.pause()
        isPlaying = false
        pushNowPlayingInfo(rate: 0.0)
    }

    func toggle() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
            pushNowPlayingInfo(rate: 0.0)
        } else {
            player.play()
            isPlaying = true
            pushNowPlayingInfo(rate: 1.0)
        }
        updateLiveActivityState()
    }

    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        progress = 0
        currentURL = nil
        queue = []
        queueIndex = 0
        activeSequenceIndex = nil
        trackTitle = ""
        trackSubtitle = ""
        removeObserver()
        nowPlayingBridge.clearNowPlaying()
        liveActivity.endActivity()
    }

    func seekToProgress(_ value: Double) {
        guard let player, let item = player.currentItem else { return }
        let duration = item.duration.seconds
        guard duration.isFinite, duration > 0 else { return }
        let seconds = duration * value
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: time) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pushNowPlayingInfo(rate: self?.isPlaying == true ? 1.0 : 0.0)
            }
        }
    }

    /// Seek to an absolute position (in seconds). Used by Control Center scrubber.
    func seekToTime(_ seconds: Double) {
        guard let player, let item = player.currentItem else { return }
        let duration = item.duration.seconds
        guard duration.isFinite, duration > 0 else { return }
        let clamped = min(max(seconds, 0), duration)
        let time = CMTime(seconds: clamped, preferredTimescale: 600)
        player.seek(to: time) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pushNowPlayingInfo(rate: self?.isPlaying == true ? 1.0 : 0.0)
            }
        }
    }

    /// Skip to the next track in the queue.
    func skipToNext() {
        guard queueIndex + 1 < queue.count else { return }
        queueIndex += 1
        playCurrentQueueItem()
    }

    /// Skip to the previous track in the queue.
    func skipToPrevious() {
        // If we're more than 3 seconds in, restart the current track instead.
        if let player, player.currentTime().seconds > 3 {
            player.seek(to: .zero)
            pushNowPlayingInfo(rate: 1.0)
            return
        }
        guard queueIndex > 0 else { return }
        queueIndex -= 1
        playCurrentQueueItem()
    }

    func queueItem(at index: Int) -> AudioQueueItem? {
        guard queue.indices.contains(index) else { return nil }
        return queue[index]
    }

    // MARK: – Queue

    private func playCurrentQueueItem() {
        guard queue.indices.contains(queueIndex) else { return }
        let item = queue[queueIndex]
        activeSequenceIndex = queueIndex
        trackSubtitle = item.subtitle
        play(from: item.url, reciterName: reciterName)
        updateLiveActivityState()
    }

    private func handlePlaybackEnded() {
        let isContinuous = UserDefaults.standard.object(forKey: "chapterReaderContinuousPlay") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "chapterReaderContinuousPlay")

        if isContinuous && queueIndex + 1 < queue.count {
            queueIndex += 1
            playCurrentQueueItem()
        } else {
            stop()
        }
    }

    // MARK: – Now Playing Info

    private func setupRemoteCommands() {
        nowPlayingBridge.register()

        nowPlayingBridge.onPlay = { [weak self] in self?.toggle() }
        nowPlayingBridge.onPause = { [weak self] in self?.pause() }
        nowPlayingBridge.onTogglePlayPause = { [weak self] in self?.toggle() }
        nowPlayingBridge.onNextTrack = { [weak self] in self?.skipToNext() }
        nowPlayingBridge.onPreviousTrack = { [weak self] in self?.skipToPrevious() }
        nowPlayingBridge.onSeek = { [weak self] time in self?.seekToTime(time) }
    }

    private func pushNowPlayingInfo(rate: Float) {
        let elapsed = player?.currentTime().seconds ?? 0
        let duration = player?.currentItem?.duration.seconds ?? 0

        // Build a descriptive title: "Surah Name · Ayah 3"
        let title: String
        if trackTitle.isEmpty == false, trackSubtitle.isEmpty == false {
            title = "\(trackTitle)\u{30FB}\(trackSubtitle)"
        } else {
            title = trackTitle.isEmpty ? trackSubtitle : trackTitle
        }

        nowPlayingBridge.updateNowPlaying(
            title: title,
            subtitle: trackSubtitle,
            artist: reciterName,
            elapsed: elapsed,
            duration: duration,
            rate: rate
        )
    }

    private func updateLiveActivityState() {
        guard queue.isEmpty == false else { return }
        liveActivity.updateActivity(
            verseLabel: trackSubtitle,
            isPlaying: isPlaying,
            currentVerse: queueIndex + 1,
            totalVerses: queue.count,
            progress: queue.count > 0 ? Double(queueIndex + 1) / Double(queue.count) : 0
        )
    }

    // MARK: – Observers

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
                // Update Now Playing progress periodically
                self.pushNowPlayingInfo(rate: self.isPlaying ? 1.0 : 0.0)
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
