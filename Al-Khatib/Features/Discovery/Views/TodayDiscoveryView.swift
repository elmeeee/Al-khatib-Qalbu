//
//  TodayDiscoveryView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct TodayDiscoveryView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("chapterReaderShowTranslation") private var showTranslation = true
    @AppStorage(ChapterReaderPreferences.translationIdKey) private var chapterTranslationId = ChapterReaderPreferences.defaultTranslationId

    @StateObject private var prayer = PrayerTimesController()
    @StateObject private var audio = AudioPlayerController()
    @State private var coordinator: TodayDiscoveryCoordinator?
    @State private var actionsViewModel = TodayVerseActionsViewModel()
    @State private var tracker: PrayerTrackerViewModel?
    @State private var showingPrayerCalendar = false
    @State private var showingTrackerCalendar = false

    let verseState: TodayVerseState

    var body: some View {
        ZStack {
            if let vm = coordinator?.discoveryViewModel {
                discoveryShell(vm)
            }

            if actionsViewModel.isGeneratingShare || actionsViewModel.publishViewModel.isPosting {
                TodayBusyOverlayView(isPosting: actionsViewModel.publishViewModel.isPosting)
            }
        }
        .allowsHitTesting(!actionsViewModel.isGeneratingShare && !actionsViewModel.publishViewModel.isPosting)
        .overlay(alignment: .top) {
            if actionsViewModel.publishViewModel.showStatus,
               let message = actionsViewModel.publishViewModel.statusMessage {
                TodayStatusToastView(message: message, isError: actionsViewModel.publishViewModel.statusIsError)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            if coordinator == nil {
                coordinator = TodayDiscoveryCoordinator(prayer: prayer, audio: audio)
            }
            if tracker == nil {
                tracker = PrayerTrackerViewModel(
                    appGroupIdentifier: container?.configuration.appGroupIdentifier,
                    controller: prayer
                )
            } else {
                tracker?.refresh()
            }
            guard let container, let coordinator else { return }
            Task { await coordinator.bootstrap(container: container, verseState: verseState) }
        }
        .onChange(of: chapterTranslationId) { _, _ in
            coordinator?.discoveryViewModel?.reloadForTranslationChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: ChapterReaderPreferences.translationDidChangeNotification)) { _ in
            coordinator?.discoveryViewModel?.reloadForTranslationChange()
        }
    }

    @ViewBuilder
    private func discoveryShell(_ vm: TodayDiscoveryViewModel) -> some View {
        VStack(spacing: 0) {
            TodayDiscoveryHeaderView(
                hijriDate: prayer.hijriDateLabel,
                gregorianDate: prayer.gregorianDateLabel,
                cityName: prayer.cityName,
                avatarURL: verseState.userAvatarURL,
                isLoggingIn: verseState.isLoggingIn,
                onAccountTap: { verseState.requestAccount() }
            )
            .background(Color.Token.panelGrey)

            ZStack {
                LinearGradient(
                    colors: [Color.Token.panelGrey, Color.Token.panelGreyAlt, Color.Token.sageTint],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)

                NavigationLink(
                    destination: PrayerCalendarView().environmentObject(prayer),
                    isActive: $showingPrayerCalendar
                ) { EmptyView() }

                NavigationLink(
                    destination: PrayerTrackerCalendarView(),
                    isActive: $showingTrackerCalendar
                ) { EmptyView() }

                ScrollView {
                    VStack(spacing: 0) {
                        prayerCard
                        if let tracker {
                            PrayerTrackerCard(viewModel: tracker, onOpenCalendar: {
                                showingTrackerCalendar = true
                            })
                            .padding(.horizontal, TodayDiscoveryLayout.horizontalInset)
                            .padding(.top, 12)
                        }
                        verseSection(vm: vm)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .refreshable {
                    await coordinator?.refreshToday(discovery: vm)
                    tracker?.refresh()
                }
            }
        }
        .background(Color.Token.deepEmerald.ignoresSafeArea(edges: .top))
        .animation(nil, value: audio.currentURL)
        .safeAreaInset(edge: .bottom) {
            if audio.currentURL != nil {
                VerseAudioBar(audio: audio)
            }
        }
        .onChangeWithFallback(of: scenePhase) { phase in
            if phase == .active {
                vm.autoRefreshDailyAyahIfNeeded(forceIfNoData: false)
                prayer.refreshIfNeeded()
                tracker?.refresh()
            }
        }
        .onChangeWithFallback(of: vm.detail?.verseKey) { newKey in
            guard let coordinator else { return }
            coordinator.onVerseKeyChanged(newKey, verseState: verseState, discovery: vm)
        }
        .onDisappear {
            coordinator?.stopAudio()
        }
        .sheet(isPresented: tafsirSheetBinding) {
            if let presenter = coordinator?.tafsirPresenter {
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
    }

    @ViewBuilder
    private func verseSection(vm: TodayDiscoveryViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            TodayVerseOfDaySectionHeaderView(verseKey: vm.detail?.verseKey)
                .padding(.top, 2)

            if let detail = vm.detail {
                TodayVerseOfDayCardView(
                    verse: detail,
                    showTranslation: showTranslation,
                    isDetailLoading: vm.isDetailLoading,
                    onAudio: { playAudio(for: detail, vm: vm) },
                    onShare: {
                        guard actionsViewModel.isGeneratingShare == false else { return }
                        Task { await actionsViewModel.presentShare(for: detail, shareProvider: vm) }
                    },
                    onReflect: {
                        guard let container else { return }
                        Task {
                            await actionsViewModel.publishReflection(
                                for: detail,
                                shareProvider: vm,
                                verseState: verseState,
                                container: container
                            )
                        }
                    },
                    onTafsir: {
                        actionsViewModel.openTafsir(
                            for: detail,
                            presenter: coordinator?.tafsirPresenter,
                            shareProvider: vm
                        )
                    },
                    audioAccessibilityHint: audioHint(vm: vm)
                )
            } else if vm.isDetailLoading {
                LoadingSkeleton()
            }

            if let error = vm.errorMessage, vm.detail == nil, vm.isDetailLoading == false {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .padding(.top)
            }
        }
        .padding(.horizontal, TodayDiscoveryLayout.horizontalInset)
        .padding(.top, 16)
        .padding(.bottom, 100)
    }

    @ViewBuilder
    private var prayerCard: some View {
        Group {
            if let dashboard = coordinator?.dashboardViewModel {
                ZStack(alignment: .topTrailing) {
                    PrayerDashboardCard(viewModel: dashboard)
                    
                    Button(action: { showingPrayerCalendar = true }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 32)
                    .padding(.top, 92)
                    .accessibilityLabel("Open Prayer Calendar")
                }
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.Token.softGrey.opacity(0.4))
                    .frame(height: 220)
                    .padding(.horizontal, TodayDiscoveryLayout.horizontalInset)
                    .padding(.top, 40)
            }
        }
    }

    private var tafsirSheetBinding: Binding<Bool> {
        Binding(
            get: { coordinator?.tafsirPresenter?.isSheetPresented ?? false },
            set: { coordinator?.tafsirPresenter?.isSheetPresented = $0 }
        )
    }

    private func playAudio(for verse: RandomAyahPayload, vm: TodayDiscoveryViewModel) {
        guard let url = verse.audio?.url else { return }
        let reciter = vm.recitations
            .first(where: { $0.id == vm.selectedRecitationId })?.displayName ?? ""
        let label = verse.verseKey.flatMap { ShareVerseCard.humanLabel(for: $0) } ?? "Quran"
        audio.playVerse(url: url, surahTitle: label, ayahLabel: reciter, reciterName: reciter)
    }

    private func audioHint(vm: TodayDiscoveryViewModel) -> String {
        AlKhatibAccessibility.VerseActions.audio(
            hint: vm.recitations.first(where: { $0.id == vm.selectedRecitationId })?.displayName ?? ""
        )
    }
}
