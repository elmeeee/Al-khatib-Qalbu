//
//  ProfileView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ProfileView: View {
    var preferSystemNavigationTitle: Bool = false
    var verseState: TodayVerseState?

    @Environment(\.appContainer) private var container
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("chapterReaderFontScale") private var fontScale = 1.0
    @AppStorage("chapterReaderShowTranslation") private var showTranslation = true
    @AppStorage(PrayerNotificationPreferences.adzanKey) private var adzanEnabled = true
    @AppStorage(PrayerNotificationPreferences.imsakKey) private var imsakEnabled = true
    @AppStorage(PrayerNotificationPreferences.midnightKey) private var midnightEnabled = true
    @AppStorage(PrayerNotificationPreferences.firstThirdKey) private var firstThirdEnabled = true
    @AppStorage(PrayerNotificationPreferences.tahajudKey) private var tahajudEnabled = true
    @AppStorage(DailyVerseNotificationPreferences.enabledKey) private var dailyVerseEnabled = true
    @AppStorage(DailyVerseNotificationPreferences.hourKey) private var dailyVerseHour = DailyVerseNotificationPreferences.defaultHour
    @AppStorage(DailyVerseNotificationPreferences.minuteKey) private var dailyVerseMinute = DailyVerseNotificationPreferences.defaultMinute
    @State private var showingDailyVerseTimeSheet = false
    @AppStorage(ChapterReaderPreferences.translationIdKey) private var selectedTranslationId = ChapterReaderPreferences.defaultTranslationId
    @AppStorage(ChapterReaderPreferences.translationNameKey) private var selectedTranslationName = ""
    @AppStorage(PrayerCalculationMethod.storageKey)
    private var prayerMethodRaw = PrayerCalculationMethod.defaultMethod.rawValue

    @State private var viewModel: ProfileViewModel?
    @State private var isOAuthPresenting = false
    @State private var showingFontScaleSheet = false
    @State private var showingTranslatorSheet = false

    var body: some View {
        ZStack {
            Color.Token.screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    generalSection
                    prayerSettingsSection
                    notificationsSection

                    if showsSignedInActions {
                        logOutButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(preferSystemNavigationTitle ? "Profile" : "")
        .navigationBarTitleDisplayMode(preferSystemNavigationTitle ? .large : .inline)
        .onAppear {
            guard let container, viewModel == nil else { return }
            viewModel = ProfileViewModel(container: container)
        }
        .task {
            guard let container else { return }
            if viewModel == nil { viewModel = ProfileViewModel(container: container) }
            await viewModel?.reloadIfNeeded()
            viewModel?.sync(to: verseState)
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserProfileDidUpdate)) { _ in
            Task { @MainActor in
                await viewModel?.hydrateFromCacheIfNeeded()
                viewModel?.sync(to: verseState)
            }
        }
        .sheet(isPresented: $showingFontScaleSheet) {
            FontScaleSheetView(fontScale: $fontScale)
        }
        .sheet(isPresented: $showingTranslatorSheet) {
            if let container {
                TranslatorSelectionSheetView(
                    selectedTranslationId: $selectedTranslationId,
                    selectedTranslationName: $selectedTranslationName,
                    contentRepository: container.content
                )
            }
        }
        .sheet(isPresented: $showingDailyVerseTimeSheet) {
            DailyVerseNotificationTimeSheetView(hour: $dailyVerseHour, minute: $dailyVerseMinute)
        }
        .onChange(of: selectedTranslationId) { _, _ in
            ChapterReaderPreferences.notifyTranslationDidChange()
        }
        .onChange(of: adzanEnabled) { _, _ in PrayerNotificationPreferences.notifyDidChange() }
        .onChange(of: imsakEnabled) { _, _ in PrayerNotificationPreferences.notifyDidChange() }
        .onChange(of: midnightEnabled) { _, _ in PrayerNotificationPreferences.notifyDidChange() }
        .onChange(of: firstThirdEnabled) { _, _ in PrayerNotificationPreferences.notifyDidChange() }
        .onChange(of: tahajudEnabled) { _, _ in PrayerNotificationPreferences.notifyDidChange() }
        .onChange(of: dailyVerseEnabled) { _, enabled in
            Task {
                await DailyVerseNotificationCoordinator.setEnabled(enabled, container: container)
            }
        }
        .onChange(of: dailyVerseHour) { _, _ in
            Task { await applyDailyVerseMorningTime() }
        }
        .onChange(of: dailyVerseMinute) { _, _ in
            Task { await applyDailyVerseMorningTime() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfOAuthWebAuthStateDidChange)) { _ in
            isOAuthPresenting = container?.oauth.isWebAuthInProgress == true
            guard isOAuthPresenting == false else { return }
            Task { @MainActor in
                await viewModel?.handleOAuthDidChange(isInProgress: false)
                viewModel?.sync(to: verseState)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                await viewModel?.handleSessionDidChange()
                viewModel?.sync(to: verseState)
            }
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        if let viewModel {
            @Bindable var viewModel = viewModel
            ProfileHeaderView(
                profile: viewModel.profile,
                fallbackName: verseState?.isLoggedIn == true ? verseState?.userDisplayName : nil,
                fallbackAvatarURL: verseState?.userAvatarURL,
                isLoading: viewModel.isLoading,
                isOAuthPresenting: isOAuthPresenting,
                onSignIn: {
                    Task {
                        await viewModel.signIn()
                        viewModel.sync(to: verseState)
                    }
                }
            )
        } else if verseState?.isLoggedIn == true {
            ProfileHeaderView(
                profile: nil,
                fallbackName: verseState?.userDisplayName,
                fallbackAvatarURL: verseState?.userAvatarURL,
                isLoading: false,
                isOAuthPresenting: isOAuthPresenting,
                onSignIn: {}
            )
        } else {
            ProfileHeaderView(
                profile: nil,
                fallbackName: nil,
                fallbackAvatarURL: nil,
                isLoading: false,
                isOAuthPresenting: isOAuthPresenting,
                onSignIn: {}
            )
        }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProfileSectionHeaderView(title: "General")
            VStack(spacing: 0) {
                Button { showingFontScaleSheet = true } label: {
                    ProfileRowView(
                        icon: "textformat.size",
                        title: "Font Size",
                        subtitle: fontScaleLabel,
                        hasToggle: false,
                        isOn: .constant(false)
                    )
                }
                .buttonStyle(.plain)
                .alKhatibAccessibility(
                    label: AlKhatibAccessibility.Profile.fontSize,
                    hint: "Current size \(fontScaleLabel). Opens font size picker"
                )
            }
            .profileCardStyle()
        }
    }

    private var prayerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProfileSectionHeaderView(title: "Prayer Setting")
            VStack(spacing: 0) {
                NavigationLink {
                    PrayerCalculationSettingsView()
                } label: {
                    ProfileRowView(
                        icon: "clock.badge.checkmark",
                        title: "Prayer calculation",
                        subtitle: selectedPrayerMethod.displayName,
                        hasToggle: false,
                        isOn: .constant(false)
                    )
                }
                .buttonStyle(.plain)
                .alKhatibAccessibility(
                    label: AlKhatibAccessibility.Profile.prayerCalculation,
                    hint: "Current method \(selectedPrayerMethod.displayName). Choose how prayer times are calculated"
                )

                Divider().padding(.leading, 64)

                ProfileRowView(
                    icon: "book.pages",
                    title: "Show Translation",
                    subtitle: "English",
                    hasToggle: true,
                    isOn: $showTranslation
                )

                Divider().padding(.leading, 64)

                Button { showingTranslatorSheet = true } label: {
                    ProfileRowView(
                        icon: "person.text.rectangle",
                        title: "Translator",
                        subtitle: selectedTranslationName,
                        hasToggle: false,
                        isOn: .constant(false)
                    )
                }
                .buttonStyle(.plain)
                .alKhatibAccessibility(
                    label: AlKhatibAccessibility.Profile.translator,
                    hint: selectedTranslationName.isEmpty
                        ? "Choose translation language for Quran text"
                        : "Current translator \(selectedTranslationName)"
                )
            }
            .profileCardStyle()
        }
    }

    private var dailyVerseNotificationSubtitle: String {
        "Today’s surah & translation in your notification"
    }

    private var dailyVerseTimeRowSubtitle: String {
        DailyVerseNotificationPreferences.formattedMorningTime(
            hour: dailyVerseHour,
            minute: dailyVerseMinute
        )
    }

    private func applyDailyVerseMorningTime() async {
        await DailyVerseNotificationCoordinator.applyMorningTime(
            hour: dailyVerseHour,
            minute: dailyVerseMinute,
            container: container
        )
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProfileSectionHeaderView(title: "Notifications")
            VStack(spacing: 0) {
                ProfileRowView(
                    icon: "book.closed.fill",
                    title: "Verse of the day",
                    subtitle: dailyVerseNotificationSubtitle,
                    hasToggle: true,
                    isOn: $dailyVerseEnabled
                )
                if dailyVerseEnabled {
                    Divider().padding(.leading, 64)
                    Button {
                        showingDailyVerseTimeSheet = true
                    } label: {
                        ProfileRowView(
                            icon: "clock.fill",
                            title: "Morning time",
                            subtitle: dailyVerseTimeRowSubtitle,
                            hasToggle: false,
                            isOn: .constant(false)
                        )
                    }
                    .buttonStyle(.plain)
                    .alKhatibAccessibility(
                        label: "Morning reminder time",
                        hint: "Currently \(dailyVerseTimeRowSubtitle). Double tap to change."
                    )
                }
                Divider().padding(.leading, 64)
                ProfileRowView(
                    icon: "bell",
                    title: "Prayer times",
                    subtitle: "Fajr, Dhuhr, Asr, Maghrib & Isha",
                    hasToggle: true,
                    isOn: $adzanEnabled
                )
                Divider().padding(.leading, 64)
                ProfileRowView(
                    icon: "bell.badge",
                    title: "Imsak",
                    subtitle: "Reminder before Fajr while fasting",
                    hasToggle: true,
                    isOn: $imsakEnabled
                )
                Divider().padding(.leading, 64)
                ProfileRowView(
                    icon: "moon",
                    title: "Midnight",
                    subtitle: "Halfway through the night",
                    hasToggle: true,
                    isOn: $midnightEnabled
                )
                Divider().padding(.leading, 64)
                ProfileRowView(
                    icon: "moon.stars",
                    title: "First third of night",
                    subtitle: "Early night rest reminder",
                    hasToggle: true,
                    isOn: $firstThirdEnabled
                )
                Divider().padding(.leading, 64)
                ProfileRowView(
                    icon: "sparkles",
                    title: "Last third (Tahajud)",
                    subtitle: "Best time for night prayer",
                    hasToggle: true,
                    isOn: $tahajudEnabled
                )
            }
            .profileCardStyle()
        }
    }

    private var logOutButton: some View {
        Button {
            Task {
                await viewModel?.signOut()
                hasCompletedOnboarding = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .bold))
                Text("Log Out")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.Token.danger)
            .clipShape(Capsule())
            .shadow(color: Color.Token.danger.opacity(0.2), radius: 8, y: 4)
        }
        .buttonStyle(PillPressStyle())
        .disabled(isOAuthPresenting)
        .opacity(isOAuthPresenting ? 0.5 : 1)
        .alKhatibAccessibility(label: AlKhatibAccessibility.Profile.signOut)
    }

    private var showsSignedInActions: Bool {
        viewModel?.profile != nil || verseState?.isLoggedIn == true
    }

    private var selectedPrayerMethod: PrayerCalculationMethod {
        PrayerCalculationMethod(rawValue: prayerMethodRaw) ?? PrayerCalculationMethod.defaultMethod
    }

    private var fontScaleLabel: String {
        switch fontScale {
        case ..<0.95: "Small"
        case 0.95 ..< 1.1: "Medium"
        case 1.1 ..< 1.22: "Large"
        default: "Extra large"
        }
    }
}

private extension View {
    func profileCardStyle() -> some View {
        background(Color.Token.pureWhite)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
    }
}
