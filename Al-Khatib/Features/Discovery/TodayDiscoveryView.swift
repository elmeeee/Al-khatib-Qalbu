//
//  SemanticDiscoveryView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI
import Combine

private enum TodayDiscoveryLayout {
    static let horizontalInset: CGFloat = 20
}

struct TodayDiscoveryView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("chapterReaderShowTranslation") private var showTranslation = true
    @State private var viewModel: TodayDiscoveryViewModel?
    @StateObject private var audio = AudioPlayerController()
    @StateObject private var prayer = PrayerTimesController()
    @State private var dashboardViewModel: PrayerDashboardViewModel?

    @State private var isGeneratingShare = false
    @State private var isPostingReflection = false
    @State private var reflectStatusMessage: String?
    @State private var reflectStatusIsError = false
    @State private var showReflectStatus = false
    @State private var tafsirPresenter: TafsirPresenter?
    @AppStorage(ChapterReaderPreferences.translationIdKey) private var chapterTranslationId = ChapterReaderPreferences.defaultTranslationId

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
            if dashboardViewModel == nil {
                dashboardViewModel = PrayerDashboardViewModel(controller: prayer)
            }
            guard let c = container, viewModel == nil else { return }
            let vm = TodayDiscoveryViewModel(content: c.content)
            viewModel = vm
            if tafsirPresenter == nil {
                tafsirPresenter = TafsirPresenter(content: c.content)
            }
            vm.autoRefreshDailyAyahIfNeeded(forceIfNoData: true)
            prayer.refreshIfNeeded()
        }
        .onChange(of: chapterTranslationId) { _, _ in
            viewModel?.reloadForTranslationChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: ChapterReaderPreferences.translationDidChangeNotification)) { _ in
            viewModel?.reloadForTranslationChange()
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
                    Task { await tafsirPresenter?.prefetch(ayahKey: newKey) }
                    if let verse = vm.detail {
                        Task { await vm.prefetchShareTextIfNeeded(for: verse) }
                    }
                }
            }
            .onDisappear {
                audio.stop()
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
    }

    private var tafsirSheetBinding: Binding<Bool> {
        Binding(
            get: { tafsirPresenter?.isSheetPresented ?? false },
            set: { tafsirPresenter?.isSheetPresented = $0 }
        )
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
                        prayerCard
                        VStack(alignment: .leading, spacing: 14) {
                            verseOfTheDaySectionHeader(verse: vm?.detail)
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
                        .padding(.horizontal, TodayDiscoveryLayout.horizontalInset)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .background(Color.Theme.deepEmerald.ignoresSafeArea(edges: .top))
        .animation(nil, value: audio.currentURL)
        .safeAreaInset(edge: .bottom) {
            if audio.currentURL != nil {
                VerseAudioBar(audio: audio)
            }
        }
    }
    
    @ViewBuilder
    private func verseOfTheDaySectionHeader(verse: RandomAyahPayload?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("✦")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.Theme.gold)
                
                Text("Verse of the Day")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.Theme.deepEmerald)
                
                Spacer()
            }
            
            if let key = verse?.verseKey {
                Text(ShareVerseCard.humanLabel(for: key))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.Theme.deepEmerald.opacity(0.6))
                    .padding(.leading, 22)
            }
            
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.Theme.gold, Color.Theme.gold.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 80, height: 3)
                Spacer()
            }
            .padding(.top, 2)
        }
    }
    
    @ViewBuilder
    private func ayahCard(for d: RandomAyahPayload) -> some View {
        VStack(spacing: 0) {
            if let key = d.verseKey {
                HStack {
                    Text(ShareVerseCard.humanLabel(for: key))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.Theme.deepEmerald)
                        )
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
            
            ornamentalDivider
                .padding(.horizontal, 24)
                .padding(.top, 14)
            
            VStack(alignment: .trailing, spacing: 0) {
                AyahArabicWebBlock(payload: d)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.Theme.deepEmerald.opacity(0.03))
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            )
            
            if showTranslation,
               let translation = d.translations?.first,
               let text = translation.text,
               text.isEmpty == false {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\u{201C}")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(Color.Theme.gold.opacity(0.5))
                        .padding(.leading, 16)
                        .offset(y: 8)
                    
                    Text(text)
                        .font(.system(size: 17, weight: .regular))
                        .lineSpacing(6)
                        .foregroundStyle(Color(hex: "#1E293B"))
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)
                    
                    HStack {
                        Spacer()
                        Text("\u{201D}")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(Color.Theme.gold.opacity(0.5))
                            .padding(.trailing, 16)
                            .offset(y: -8)
                    }
                }
                .padding(.bottom, 8)
            }
            
            ornamentalDivider
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
            
            actionButtonRow(for: d)
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
        }
        .transaction { txn in txn.animation = nil }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(hex: "#F0FDF4")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.Theme.deepEmerald.opacity(0.15), Color.Theme.softGrey.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.Theme.deepEmerald.opacity(0.06), radius: 12, x: 0, y: 6)
    }
    
    private var ornamentalDivider: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.Theme.softGrey.opacity(0.1), Color.Theme.gold.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            Text("◆")
                .font(.system(size: 6))
                .foregroundColor(Color.Theme.gold.opacity(0.6))
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.Theme.gold.opacity(0.3), Color.Theme.softGrey.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }
    
    
    @ViewBuilder
    private func actionButtonRow(for d: RandomAyahPayload) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
        
        LazyVGrid(columns: columns, spacing: 8) {
            actionPill(
                icon: "speaker.wave.2.fill",
                text: "Audio",
                tint: Color.Theme.deepEmerald
            ) {
                if let u = d.audio?.url {
                    let reciterLabel = viewModel?.recitations
                        .first(where: { $0.id == viewModel?.selectedRecitationId })?.displayName ?? ""
                    let verseLabel = d.verseKey
                        .flatMap { ShareVerseCard.humanLabel(for: $0) } ?? "Quran"
                    audio.playVerse(
                        url: u,
                        surahTitle: verseLabel,
                        ayahLabel: reciterLabel,
                        reciterName: reciterLabel
                    )
                }
            }
            
            actionPill(
                icon: "square.and.arrow.up",
                text: "Share",
                tint: Color(hex: "#2563EB")
            ) {
                guard !isGeneratingShare else { return }
                isGeneratingShare = true
                Task {
                    await presentShare(for: d)
                    await MainActor.run { isGeneratingShare = false }
                }
            }
            
            actionPill(
                icon: "lightbulb.fill",
                text: "Reflect",
                tint: Color.Theme.gold
            ) {
                guard !isPostingReflection, !isGeneratingShare else { return }
                Task { await publishReflection(for: d) }
            }
            
            actionPill(
                icon: "book.closed.fill",
                text: "Tafsir",
                tint: Color(hex: "#4F46E5")
            ) {
                openTafsir(for: d)
            }
        }
    }
    
    @ViewBuilder
    private func actionPill(icon: String, text: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(text)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(tint.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(tint.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PillPressStyle())
    }

    @MainActor
    private func openTafsir(for verse: RandomAyahPayload) {
        tafsirPresenter?.open(for: verse)
        Task { await viewModel?.prefetchShareTextIfNeeded(for: verse) }
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
        }
        guard verseState.isLoggedIn, let authorId = verseState.userId, authorId.isEmpty == false else {
            await showReflectStatus("Please sign in to publish a reflection.", isError: true)
            return
        }

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
                verseState.requestAccount()
            } label: {
                profileAvatarIcon
            }
            .disabled(verseState.isLoggingIn)
        }
        .padding(.horizontal, TodayDiscoveryLayout.horizontalInset)
        .padding(.top, 16)
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
        Group {
            if let dbVM = dashboardViewModel {
                PrayerDashboardCard(viewModel: dbVM)
            } else {
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.Theme.softGrey.opacity(0.4))
                        .frame(height: 220)
                }
                .padding(.horizontal, TodayDiscoveryLayout.horizontalInset)
                .padding(.top, 40)
            }
        }
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

