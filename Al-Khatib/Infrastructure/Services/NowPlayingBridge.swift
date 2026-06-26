//
//  NowPlayingBridge.swift
//  Al-Khatib
//
//  Created by Elmee on 26/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import MediaPlayer

/// Bridges `AudioPlayerController` to the system Now Playing info center
/// (Control Center + Lock Screen) and remote command center.
///
/// This is a pure infrastructure service — it knows nothing about SwiftUI.
/// The controller feeds data in; the bridge pushes it to MPNowPlayingInfoCenter
/// and routes MPRemoteCommandCenter events back via closures.
@MainActor
final class NowPlayingBridge {

    // MARK: – Callbacks from remote commands

    var onPlay: (() -> Void)?
    var onPause: (() -> Void)?
    var onTogglePlayPause: (() -> Void)?
    var onNextTrack: (() -> Void)?
    var onPreviousTrack: (() -> Void)?
    var onSeek: ((Double) -> Void)?

    // MARK: – State

    private var isRegistered = false

    // MARK: – Public API

    /// Call once when audio playback starts for the first time.
    func register() {
        guard !isRegistered else { return }
        isRegistered = true

        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.onPlay?() }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.onPause?() }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.onTogglePlayPause?() }
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.onNextTrack?() }
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.onPreviousTrack?() }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let posEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in self?.onSeek?(posEvent.positionTime) }
            return .success
        }
    }

    /// Update the system Now Playing info with current track metadata.
    func updateNowPlaying(
        title: String,
        subtitle: String,
        artist: String,
        elapsed: Double,
        duration: Double,
        rate: Float
    ) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title.isEmpty ? "Al-Khatib" : title,
            MPMediaItemPropertyArtist: artist.isEmpty ? subtitle : artist,
            MPMediaItemPropertyAlbumTitle: subtitle,
            MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: rate),
            MPNowPlayingInfoPropertyDefaultPlaybackRate: NSNumber(value: 1.0)
        ]

        if duration.isFinite, duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: duration)
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: elapsed)
        }

        // Use the app icon as artwork
        if let image = UIImage(named: "AppIcon") ?? UIImage(named: "quran_icon") {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Clear Now Playing info when playback stops.
    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    /// Unregister all remote command targets.
    func unregister() {
        guard isRegistered else { return }
        isRegistered = false

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
    }

    deinit {
        // Best-effort cleanup — deinit may not run on @MainActor.
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
    }
}
