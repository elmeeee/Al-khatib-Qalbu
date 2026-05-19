//
//  SemanticDiscoveryView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI
import Combine

struct TodayDiscoveryView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: TodayDiscoveryViewModel?
    @StateObject private var audio = AudioPlayerController()
    @StateObject private var prayer = PrayerTimesController()

    @State private var isGeneratingShare = false
    @State private var isPostingReflection = false
    @State private var reflectStatusMessage: String?
    @State private var reflectStatusIsError = false
    @State private var showReflectStatus = false
    @State private var isTafsirSheetPresented = false
    @State private var isTafsirLoading = false
    @State private var tafsirHTML = ""
    @State private var tafsirError: String?
    @State private var tafsirAyahKey: String?
    @State private var tafsirVerseReference = ""
    @State private var tafsirSourceName: String?
    @State private var tafsirContentUnavailable = false
    @State private var tafsirCache: [String: CachedTafsir] = [:]

    let verseState: TodayVerseState

    var body: some View {
        ZStack {
            if let vm = viewModel {
                content(vm)
            }

            if isGeneratingShare || isPostingReflection {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    ProgressView()
                        .tint(Color.Theme.deepEmerald)
                        .scaleEffect(1.1)
                    Text(isPostingReflection ? "Publishing your reflection..." : "Preparing your share...")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.Theme.deepEmerald)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.96))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.Theme.softGrey.opacity(0.8), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
            }
        }
        .allowsHitTesting(!isGeneratingShare && !isPostingReflection)
        .overlay(alignment: .top) {
            if showReflectStatus, let reflectStatusMessage {
                Text(reflectStatusMessage)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(reflectStatusIsError ? Color.red : Color.Theme.deepEmerald)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            guard let c = container, viewModel == nil else { return }
            let vm = TodayDiscoveryViewModel(
                semantic: c.semantic,
                content: c.content
            )
            viewModel = vm
            vm.autoRefreshDailyAyahIfNeeded(forceIfNoData: true)
            prayer.refreshIfNeeded()
        }
    }

    @ViewBuilder
    private func content(_ vm: TodayDiscoveryViewModel) -> some View {
        discoveryShell(vm: vm)
            .onChangeWithFallback(of: scenePhase) { phase in
                if phase == .active {
                    vm.autoRefreshDailyAyahIfNeeded(forceIfNoData: false)
                    prayer.refreshIfNeeded()
                }
            }
            .onChangeWithFallback(of: vm.detail?.verseKey) { newKey in
                let arabic = vm.detail?.displayText ?? ""
                let label = newKey.flatMap { ShareVerseCard.humanLabel(for: $0) }
                verseState.setVerse(key: newKey, label: label, arabic: arabic)
                if let newKey {
                    Task { await prefetchTafsirIfNeeded(for: newKey) }
                    if let verse = vm.detail {
                        Task { await vm.prefetchShareTextIfNeeded(for: verse) }
                    }
                }
            }
            .onDisappear {
                audio.stop()
            }
            .sheet(isPresented: $isTafsirSheetPresented) {
                TafsirReaderSheet(
                    verseReference: tafsirVerseReference,
                    commentarySource: tafsirSourceName,
                    isLoading: isTafsirLoading,
                    loadErrorDescription: tafsirError,
                    commentaryUnavailable: tafsirContentUnavailable,
                    htmlFragment: tafsirHTML,
                    reload: { Task { await loadTafsir() } }
                )
            }
    }

    @ViewBuilder
    private func discoveryShell(vm: TodayDiscoveryViewModel?) -> some View {
        VStack(spacing: 0) {
            prayerHeader
                .background(Color(hex: "#E8EBEF"))

            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "#E8EBEF"),
                        Color(hex: "#EEF2EE"),
                        Color(hex: "#E7F0DF")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 88)
                        prayerCard
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Verse of the Day")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color.Theme.deepEmerald)
                                Spacer()
                                Button {
                                    vm?.loadDailyAyahWithHadith()
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color.Theme.deepEmerald)
                                        .padding(8)
                                        .background(Color.white.opacity(0.8))
                                        .clipShape(Circle())
                                }
                                .disabled(vm == nil)
                            }
                            .padding(.top, 2)

                            if vm == nil || vm?.isDetailLoading == true {
                                LoadingSkeleton()
                            } else if let d = vm?.detail {
                                ayahCard(for: d)
                            }

                            if let e = vm?.errorMessage {
                                Text(e)
                                    .foregroundStyle(.red)
                                    .font(.footnote)
                                    .padding(.top)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .background(Color.Theme.deepEmerald.ignoresSafeArea(edges: .top))
        .animation(nil, value: audio.currentURL)
        .safeAreaInset(edge: .bottom) {
            if audio.currentURL != nil {
                audioBar
            }
        }
    }

    @ViewBuilder
    private func ayahCard(for d: RandomAyahPayload) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                if let key = d.verseKey {
                    HStack {
                        Text(ShareVerseCard.humanLabel(for: key))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.Theme.deepEmerald)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }

                VStack(alignment: .trailing, spacing: 0) {
                    AyahArabicWebBlock(payload: d)
                        .padding(.top, 8)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 14)
                }
                .frame(maxWidth: .infinity, alignment: .topTrailing)

                if let translation = d.translations?.first {
                    Text(translation.text ?? "")
                        .font(.system(size: 16))
                        .lineSpacing(3)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                }
            }
            .background(Color.Theme.pureWhite)

            Rectangle()
                .fill(Color.Theme.deepEmerald)
                .frame(height: 4)

            HStack(spacing: 0) {
                actionButton(icon: "speaker.wave.2.fill", text: "Audio") {
                    if let u = d.audio?.url {
                        let reciterLabel = viewModel?.recitations
                            .first(where: { $0.id == viewModel?.selectedRecitationId })?.displayName ?? ""
                        audio.play(from: u, reciterName: reciterLabel)
                    }
                }
                actionButton(icon: "square.and.arrow.up", text: "Share") {
                    guard !isGeneratingShare else { return }
                    isGeneratingShare = true
                    Task {
                        await presentShare(for: d)
                        await MainActor.run { isGeneratingShare = false }
                    }
                }
                actionButton(icon: "lightbulb.fill", text: "Reflect") {
                    guard !isPostingReflection, !isGeneratingShare else { return }
                    Task { await publishReflection(for: d) }
                }
                actionButton(icon: "book.closed.fill", text: "Tafsir") {
                    openTafsir(for: d)
                }
            }
            .padding(.vertical, 14)
        }
        .transaction { txn in txn.animation = nil }
        .background(Color.Theme.pureWhite.opacity(0.96))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.Theme.softGrey, lineWidth: 1))
    }

    @ViewBuilder
    private func actionButton(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(text)
                    .font(.caption)
            }
            .foregroundColor(Color.Theme.deepEmerald)
            .frame(maxWidth: .infinity)
        }
    }

    @MainActor
    private func openTafsir(for verse: RandomAyahPayload) {
        guard let key = resolvedAyahKey(for: verse) else { return }
        tafsirAyahKey = key
        tafsirVerseReference = ShareVerseCard.humanLabel(for: key)
        tafsirSourceName = nil
        tafsirHTML = ""
        tafsirError = nil
        tafsirContentUnavailable = false
        isTafsirLoading = true
        isTafsirSheetPresented = true
        Task { await loadTafsir() }
        Task { await viewModel?.prefetchShareTextIfNeeded(for: verse) }
    }

    @MainActor
    private func loadTafsir() async {
        guard let key = tafsirAyahKey else { return }
        isTafsirLoading = true
        tafsirError = nil
        tafsirContentUnavailable = false
        do {
            let cached = try await loadTafsirCached(for: key)
            tafsirSourceName = cached.sourceName
            tafsirHTML = cached.html
            tafsirContentUnavailable = cached.html.isEmpty
        } catch {
            tafsirError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            tafsirHTML = ""
            tafsirContentUnavailable = false
            tafsirSourceName = nil
        }
        isTafsirLoading = false
    }

    @MainActor
    private func presentShare(for verse: RandomAyahPayload) async {
        guard let vm = viewModel else { return }
        let text = await vm.prepareShareText(for: verse)
        ShareVerseCard.presentPrepared(text: text)
    }

    @MainActor
    private func publishReflection(for verse: RandomAyahPayload) async {
        guard let c = container, let vm = viewModel else { return }
        isPostingReflection = true
        defer { isPostingReflection = false }

        await verseState.ensureProfileLoaded(container: c)
        if verseState.isLoggedIn == false {
            await verseState.signIn(container: c)
            await verseState.ensureProfileLoaded(container: c)
        }
        guard verseState.isLoggedIn else { return }

        guard let authorId = verseState.userId, authorId.isEmpty == false else {
            await showReflectStatus("Could not load your profile. Try signing in again.", isError: true)
            return
        }

        // Reuse cached AI text — do not call Groq again on publish.
        let body = vm.cachedShareText(for: verse) ?? vm.quickReflectionText(for: verse)
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 6 else {
            await showReflectStatus("Reflection is too short to publish.", isError: true)
            return
        }

        let verseKey = resolvedAyahKey(for: verse)
        let day = {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            fmt.timeZone = .current
            return fmt.string(from: .now)
        }()
        let idempotencyKey = verseKey.map { "reflect:\($0):\(day)" }

        do {
            _ = try await c.reflect.createReflectionPost(
                body: trimmed,
                verseKey: verseKey,
                authorId: authorId,
                idempotencyKey: idempotencyKey
            )
            verseState.notifyFeedDidUpdate()
            await showReflectStatus("Reflection published!", isError: false)
            // Already posted — open Reflect feed only, not the compose sheet.
            verseState.requestReflect()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            await showReflectStatus(message, isError: true)
        }
    }

    @MainActor
    private func showReflectStatus(_ message: String, isError: Bool) async {
        reflectStatusMessage = message
        reflectStatusIsError = isError
        withAnimation { showReflectStatus = true }
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        withAnimation { showReflectStatus = false }
    }

    private func resolvedAyahKey(for verse: RandomAyahPayload) -> String? {
        guard let key = verse.verseKey, !key.isEmpty else { return nil }
        return key
    }

    @MainActor
    private func prefetchTafsirIfNeeded(for ayahKey: String) async {
        guard tafsirCache[ayahKey] == nil else { return }
        _ = try? await loadTafsirCached(for: ayahKey)
    }

    @MainActor
    private func loadTafsirCached(for ayahKey: String) async throws -> CachedTafsir {
        if let cached = tafsirCache[ayahKey] { return cached }
        guard let repository = container?.content else {
            throw NSError(domain: "AppContainer", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "App container is unavailable."])
        }
        let response = try await repository.getTafsirByAyah(resourceId: "169", ayahKey: ayahKey)
        let html = response.tafsir?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let plainText = response.tafsir?.textStrippingHTML?.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceName = response.tafsir?.resourceName ?? "Tafsir Ibn Kathir (English)"
        let result = CachedTafsir(html: html, plainText: plainText, sourceName: sourceName)
        tafsirCache[ayahKey] = result
        return result
    }

    private var audioBar: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Theme.gold.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "waveform")
                        .foregroundColor(Color.Theme.gold)
                )

            VStack(alignment: .leading, spacing: 2) {
                let trackName = viewModel?.detail?.verseKey
                    .flatMap { ShareVerseCard.humanLabel(for: $0) } ?? ""
                Text(trackName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(audio.reciterName)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Button { audio.toggle() } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 44)
            }

            Button { audio.stop() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 44)
            }
        }
        .padding(8)
        .background(Capsule().fill(.regularMaterial))
        .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.12), radius: 10, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

extension TodayDiscoveryView {
    private var prayerHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                RotatingPrayerDateLabel(
                    hijri: prayer.hijriDateLabel,
                    gregorian: prayer.gregorianDateLabel
                )

                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.system(size: 14))
                    Text(prayer.cityName ?? "")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .padding(.leading, 2)
                }
                .foregroundColor(Color.Theme.deepEmerald)
            }

            Spacer()

            Button {
                if verseState.isLoggedIn {
                    verseState.requestAccount()
                } else {
                    Task { await verseState.signIn(container: container) }
                }
            } label: {
                profileAvatarIcon
            }
            .disabled(verseState.isLoggingIn)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                await verseState.ensureProfileLoaded(container: container)
            }
        }
    }

    @ViewBuilder
    private var profileAvatarIcon: some View {
        if verseState.isLoggingIn {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .overlay(ProgressView().tint(Color.Theme.deepEmerald))
        } else if let avatarURL = verseState.userAvatarURL {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.Theme.deepEmerald.opacity(0.3), lineWidth: 1.5))
                case .failure:
                    fallbackProfileIcon
                case .empty:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .overlay(ProgressView().tint(Color.Theme.deepEmerald))
                @unknown default:
                    fallbackProfileIcon
                }
            }
        } else {
            fallbackProfileIcon
        }
    }

    private var fallbackProfileIcon: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Color.Theme.deepEmerald)
            )
    }

    private var prayerCard: some View {
        let skeleton = prayer.isLoading && (prayer.nextPrayerName?.isEmpty ?? true)
        return VStack(spacing: 0) {
            PrayerArcCardLiveContent(prayer: prayer, prayerArcSkeleton: skeleton)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "#E8EBEF"), Color(hex: "#EEF2EE")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct RotatingPrayerDateLabel: View {
    let hijri: String?
    let gregorian: String?
    var interval: TimeInterval = 7

    @State private var showHijri = true

    private var canRotate: Bool {
        guard let hijri, let gregorian, hijri.isEmpty == false, gregorian.isEmpty == false else {
            return false
        }
        return true
    }

    private var displayedText: String? {
        if canRotate {
            return showHijri ? hijri : gregorian
        }
        if let hijri, hijri.isEmpty == false { return hijri }
        if let gregorian, gregorian.isEmpty == false { return gregorian }
        return nil
    }

    var body: some View {
        Group {
            if let displayedText {
                Text(displayedText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.Theme.deepEmerald.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.4), value: showHijri)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
        .onReceive(
            Timer.publish(every: interval, on: .main, in: .common).autoconnect()
        ) { _ in
            guard canRotate else { return }
            showHijri.toggle()
        }
        .onChange(of: hijri) { _, _ in showHijri = true }
        .onChange(of: gregorian) { _, _ in showHijri = true }
    }
}

private struct PrayerArcCardLiveContent: View {
    @ObservedObject var prayer: PrayerTimesController
    @StateObject private var clock = PrayerUIClock()
    var prayerArcSkeleton: Bool

    var body: some View {
        let now = clock.now
        ZStack {
            Circle()
                .trim(from: 0.0, to: 0.5)
                .stroke(Color.white.opacity(0.7),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round))
                .rotationEffect(.degrees(180))
                .frame(width: 280, height: 280)

            Circle()
                .trim(from: 0.0, to: CGFloat(prayer.progressClamped(at: now) * 0.5))
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "#00D49C"), Color.Theme.deepEmerald],
                        startPoint: .trailing,
                        endPoint: .leading
                    ),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                .rotationEffect(.degrees(180))
                .frame(width: 280, height: 280)
                .opacity(prayerArcSkeleton ? 0.25 : 1)

            if prayerArcSkeleton {
                VStack(spacing: 12) {
                    SkeletonBar(width: 180, height: 34, cornerRadius: 10)
                    SkeletonBar(width: 120, height: 14, cornerRadius: 6)
                    SkeletonCapsuleBar().frame(width: 160, height: 36)
                }
                .offset(y: -10)
            } else {
                VStack(spacing: 8) {
                    Text(prayer.nextPrayerName ?? "")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color.Theme.deepEmerald)

                    Text("In")
                        .font(.system(size: 16))
                        .foregroundColor(Color.Theme.deepEmerald.opacity(0.9))
                        .padding(.bottom, 8)

                    if let remaining = prayer.remainingText(at: now) {
                        Text(remaining)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.Theme.deepEmerald)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.8))
                                    .overlay(Capsule().stroke(Color.Theme.deepEmerald.opacity(0.4), lineWidth: 1))
                            )
                    }

                    HStack(spacing: 8) {
                        prayerPill(label: "Current", name: nil, time: prayer.nextPrayerTime)
                        prayerPill(label: "Next", name: prayer.followingPrayerName, time: prayer.followingPrayerTime)
                    }
                    .padding(.top, 4)
                }
                .offset(y: -2)
            }
        }
        .frame(height: 200)
        .padding(.vertical, 12)
        .animation(nil, value: now)
        .transaction { $0.animation = nil }
    }

    @ViewBuilder
    private func prayerPill(label: String, name: String?, time: String?) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.Theme.deepEmerald.opacity(0.72))
            if let name { Text(name).font(.system(size: 12, weight: .semibold)).foregroundColor(Color.Theme.deepEmerald) }
            Text(time ?? "--:--")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.Theme.deepEmerald)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.74))
                .overlay(Capsule().stroke(Color.Theme.deepEmerald.opacity(0.26), lineWidth: 0.8))
        )
    }
}

private struct TafsirReaderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let verseReference: String
    let commentarySource: String?
    let isLoading: Bool
    let loadErrorDescription: String?
    let commentaryUnavailable: Bool
    let htmlFragment: String
    let reload: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.Theme.offWhite, Color(hex: "#F1F5F2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetTopBar
                verseContextHeader
                Divider().opacity(0.55)

                Group {
                    let hasHTML = !htmlFragment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    if isLoading || (!hasHTML && loadErrorDescription == nil && !commentaryUnavailable) {
                        tafsirLoadingBody
                    } else if loadErrorDescription != nil {
                        tafsirErrorBody
                    } else if commentaryUnavailable {
                        tafsirEmptyBody
                    } else {
                        HTMLContentWebView(htmlFragment: htmlFragment, style: .tafsirReader)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(22)
        .animation(nil, value: isLoading)
        .animation(nil, value: htmlFragment)
    }

    private var sheetTopBar: some View {
        HStack {
            Text("Tafsir")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.Theme.deepEmerald)
            Spacer()
            Button("Done") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.Theme.deepEmerald)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var verseContextHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "text.alignleft")
                .font(.title2)
                .foregroundStyle(Color.Theme.deepEmerald.opacity(0.88))
                .frame(width: 36, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text(verseReference)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.Theme.deepEmerald)
                    .multilineTextAlignment(.leading)

                Group {
                    if isLoading {
                        SkeletonBar(width: 180, height: 11, cornerRadius: 5)
                    } else if let source = commentarySource {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Image(systemName: "book.pages.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 14, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.Theme.softGrey.opacity(0.65), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .animation(nil, value: isLoading)
        .animation(nil, value: commentarySource ?? "")
    }

    private var tafsirLoadingBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SkeletonBar(width: nil, height: 14, cornerRadius: 6)
                SkeletonBar(width: nil, height: 14, cornerRadius: 6)
                SkeletonBar(width: 280, height: 14, cornerRadius: 6)
                SkeletonBar(width: nil, height: 14, cornerRadius: 6)
                SkeletonBar(width: nil, height: 14, cornerRadius: 6)
                SkeletonBar(width: 220, height: 14, cornerRadius: 6)
                ForEach(0..<6, id: \.self) { i in
                    SkeletonBar(
                        width: i % 3 == 0 ? nil : CGFloat(300 - i * 12),
                        height: 12,
                        cornerRadius: 5
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
    }

    @ViewBuilder
    private var tafsirErrorBody: some View {
        if let desc = loadErrorDescription {
            ContentUnavailableView {
                Label("Couldn't load tafsir", systemImage: "wifi.exclamationmark")
            } description: {
                Text(desc)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            } actions: {
                Button("Try again", action: reload)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.Theme.deepEmerald)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var tafsirEmptyBody: some View {
        ContentUnavailableView {
            Label("No commentary here", systemImage: "text.book.closed")
        } description: {
            Text("This verse doesn't include tafsir text for this source yet.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct CachedTafsir {
    let html: String
    let plainText: String?
    let sourceName: String
}

private struct AyahArabicWebBlock: View {
    let payload: RandomAyahPayload
    @State private var webHeight: CGFloat = 160

    var body: some View {
        HTMLContentWebView(
            htmlFragment: payload.arabicFragmentForWebView(),
            style: .verseCard,
            contentHeight: $webHeight
        )
        .frame(height: webHeight)
        .animation(nil, value: webHeight)
        .frame(maxWidth: .infinity)
        .id(stableId)
        .onChangeWithFallback(of: payload.verseKey ?? "") { _ in webHeight = 160 }
    }

    private var stableId: String {
        if let key = payload.verseKey { return key }
        if let id = payload.id { return "id-\(id)" }
        return "ayah"
    }
}
