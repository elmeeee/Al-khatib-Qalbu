//
//  ProfileView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI
internal import UIKit

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
    @State private var showNotificationDeniedAlert = false
    @State private var notificationAlertMessage = ""
    @AppStorage(ChapterReaderPreferences.translationIdKey) private var selectedTranslationId = ChapterReaderPreferences.defaultTranslationId
    @AppStorage(ChapterReaderPreferences.translationNameKey) private var selectedTranslationName = ""
    @AppStorage(PrayerCalculationMethod.storageKey)
    private var prayerMethodRaw = PrayerCalculationMethod.defaultMethod.rawValue

    @State private var viewModel: ProfileViewModel?
    @State private var isOAuthPresenting = false
    @State private var showingFontScaleSheet = false
    @State private var showingTranslatorSheet = false
    @AppStorage("selected_adhan_sound") private var selectedAdhanSound = "default"
    @State private var showingAdhanVoiceSheet = false
    
    @ObservedObject var languageManager = AppLanguageManager.shared
    @State private var showingAppLanguageSheet = false

    var body: some View {
        ZStack {
            // Subtle two-tone background
            LinearGradient(
                colors: [Color.Token.screenBackground, Color.Token.sageMist],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    generalSection
                    prayerSettingsSection
                    notificationsSection

                    if showsSignedInActions {
                        logOutButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle(preferSystemNavigationTitle ? languageManager.localize("tab_profile") : "")
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
            if dailyVerseEnabled {
                let result = await DailyVerseNotificationCoordinator.refreshIfNeeded(container: container)
                handleDailyVerseScheduleResult(result)
            }
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
        .sheet(isPresented: $showingAppLanguageSheet) {
            AppLanguageSelectionSheet(selectedLanguage: $languageManager.currentLanguage)
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
        .sheet(isPresented: $showingAdhanVoiceSheet) {
            AdhanVoiceSelectionSheet()
        }
        .sheet(isPresented: $showingDailyVerseTimeSheet) {
            DailyVerseNotificationTimeSheetView(
                hour: $dailyVerseHour,
                minute: $dailyVerseMinute,
                onSaved: {
                    Task { await applyDailyVerseMorningTime() }
                }
            )
        }
        .alert(languageManager.localize("notif_disabled_title"), isPresented: $showNotificationDeniedAlert) {
            Button(languageManager.localize("open_settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(languageManager.localize("close"), role: .cancel) {}
        } message: {
            Text(notificationAlertMessage)
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
                let result = await DailyVerseNotificationCoordinator.setEnabled(enabled, container: container)
                handleDailyVerseScheduleResult(result)
            }
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
        VStack(alignment: .leading, spacing: 10) {
            ProfileSectionHeaderView(title: languageManager.localize("general"))
            VStack(spacing: 0) {
                Button { showingFontScaleSheet = true } label: {
                    ProfileRowView(
                        icon: "textformat.size",
                        title: languageManager.localize("font_size"),
                        subtitle: fontScaleLabel,
                        hasToggle: false,
                        iconTint: Color.Token.indigoAccent,
                        isOn: .constant(false)
                    )
                }
                .buttonStyle(.plain)
                .alKhatibAccessibility(
                    label: AlKhatibAccessibility.Profile.fontSize,
                    hint: "Current size \(fontScaleLabel). Opens font size picker"
                )

                Divider().padding(.leading, 66)

                Button { showingAppLanguageSheet = true } label: {
                    ProfileRowView(
                        icon: "globe",
                        title: languageManager.localize("app_language"),
                        subtitle: languageManager.currentLanguage.displayName,
                        hasToggle: false,
                        iconTint: Color.Token.teal,
                        isOn: .constant(false)
                    )
                }
                .buttonStyle(.plain)
            }
            .profileCardStyle()
        }
    }

    private var prayerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProfileSectionHeaderView(title: languageManager.localize("prayer_setting"))
            VStack(spacing: 0) {
                NavigationLink {
                    LocationSettingsView()
                } label: {
                    ProfileRowView(
                        icon: "location.circle",
                        title: languageManager.localize("location_source"),
                        subtitle: "",
                        hasToggle: false,
                        iconTint: Color.Token.teal,
                        isOn: .constant(false)
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 66)

                NavigationLink {
                    PrayerCalculationSettingsView()
                } label: {
                    ProfileRowView(
                        icon: "clock.badge.checkmark",
                        title: languageManager.localize("prayer_calc"),
                        subtitle: selectedPrayerMethod.displayName,
                        hasToggle: false,
                        iconTint: Color.Token.deepEmerald,
                        isOn: .constant(false)
                    )
                }
                .buttonStyle(.plain)
                .alKhatibAccessibility(
                    label: AlKhatibAccessibility.Profile.prayerCalculation,
                    hint: "Current method \(selectedPrayerMethod.displayName). Choose how prayer times are calculated"
                )

                Divider().padding(.leading, 66)

                ProfileRowView(
                    icon: "book.pages",
                    title: languageManager.localize("show_translation"),
                    subtitle: languageManager.localize("show_translation"),
                    hasToggle: true,
                    iconTint: Color.Token.gold,
                    isOn: $showTranslation
                )

                Divider().padding(.leading, 66)

                Button { showingTranslatorSheet = true } label: {
                    ProfileRowView(
                        icon: "person.text.rectangle",
                        title: languageManager.localize("translator"),
                        subtitle: selectedTranslationName,
                        hasToggle: false,
                        iconTint: Color.Token.goldDeep,
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

                Divider().padding(.leading, 66)

                Button { showingAdhanVoiceSheet = true } label: {
                    ProfileRowView(
                        icon: "waveform",
                        title: languageManager.localize("adhan_voice"),
                        subtitle: adhanVoiceDisplayName,
                        hasToggle: false,
                        iconTint: Color(hex: "#7C3AED"),
                        isOn: .constant(false)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(languageManager.localize("adhan_voice"))
                .accessibilityHint("Current voice: \(adhanVoiceDisplayName). Choose the voice for Adhan notifications")
            }
            .profileCardStyle()
        }
    }

    private var adhanVoiceDisplayName: String {
        switch selectedAdhanSound {
        case "default": return languageManager.localize("system_default")
        case "adhan_ust_daeng_syawal_indonesia": return "Ust. Daeng Syawal (ID)"
        case "adhan_ustaz_sadid_ahmad_dahri_singapore": return "Ust. Sadid Ahmad Dahri (SG)"
        case "adhan_omar_hisham_al_arabi": return "Omar Hisham Al Arabi"
        case "adhan_sheikh_abdul_karim_malaysia": return "Sheikh Abdul Karim (MY)"
        case "adhan_fajr_mishary_alafasy": return "Mishary Alafasy (Fajr)"
        default: return languageManager.localize("system_default")
        }
    }

    private var dailyVerseNotificationSubtitle: String {
        languageManager.localize("daily_verse_sub")
    }

    private var dailyVerseTimeRowSubtitle: String {
        DailyVerseNotificationPreferences.formattedMorningTime(
            hour: dailyVerseHour,
            minute: dailyVerseMinute
        )
    }

    private func applyDailyVerseMorningTime() async {
        let result = await DailyVerseNotificationCoordinator.applyMorningTime(
            hour: dailyVerseHour,
            minute: dailyVerseMinute,
            container: container
        )
        handleDailyVerseScheduleResult(result)
    }

    private func handleDailyVerseScheduleResult(_ result: DailyVerseNotificationScheduler.ScheduleResult) {
        switch result {
        case .scheduled, .disabled:
            break
        case .authorizationDenied:
            notificationAlertMessage = languageManager.localize("notif_disabled_msg")
            showNotificationDeniedAlert = true
        case .failed(let message):
            notificationAlertMessage = message
            showNotificationDeniedAlert = true
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProfileSectionHeaderView(title: languageManager.localize("notifications"))
            VStack(spacing: 0) {
                ProfileRowView(
                    icon: "book.closed.fill",
                    title: languageManager.localize("verse_of_the_day"),
                    subtitle: dailyVerseNotificationSubtitle,
                    hasToggle: true,
                    iconTint: Color.Token.gold,
                    isOn: $dailyVerseEnabled
                )
                if dailyVerseEnabled {
                    Divider().padding(.leading, 66)
                    Button {
                        showingDailyVerseTimeSheet = true
                    } label: {
                        ProfileRowView(
                            icon: "clock.fill",
                            title: languageManager.localize("morning_time"),
                            subtitle: dailyVerseTimeRowSubtitle,
                            hasToggle: false,
                            iconTint: Color.Token.goldDeep,
                            isOn: .constant(false)
                        )
                    }
                    .buttonStyle(.plain)
                    .alKhatibAccessibility(
                        label: "Morning reminder time",
                        hint: "Currently \(dailyVerseTimeRowSubtitle). Double tap to change."
                    )
                }
                Divider().padding(.leading, 66)
                ProfileRowView(
                    icon: "bell",
                    title: languageManager.localize("prayer_times"),
                    subtitle: languageManager.localize("prayer_times_sub"),
                    hasToggle: true,
                    iconTint: Color.Token.teal,
                    isOn: $adzanEnabled
                )
                Divider().padding(.leading, 66)
                ProfileRowView(
                    icon: "bell.badge",
                    title: languageManager.localize("imsak"),
                    subtitle: languageManager.localize("imsak_sub"),
                    hasToggle: true,
                    iconTint: Color.Token.tealDark,
                    isOn: $imsakEnabled
                )
                Divider().padding(.leading, 66)
                ProfileRowView(
                    icon: "moon",
                    title: languageManager.localize("midnight"),
                    subtitle: languageManager.localize("midnight_sub"),
                    hasToggle: true,
                    iconTint: Color.Token.indigoDeep,
                    isOn: $midnightEnabled
                )
                Divider().padding(.leading, 66)
                ProfileRowView(
                    icon: "moon.stars",
                    title: languageManager.localize("first_third_night"),
                    subtitle: languageManager.localize("first_third_sub"),
                    hasToggle: true,
                    iconTint: Color(hex: "#4338CA"),
                    isOn: $firstThirdEnabled
                )
                Divider().padding(.leading, 66)
                ProfileRowView(
                    icon: "sparkles",
                    title: languageManager.localize("tahajud"),
                    subtitle: languageManager.localize("tahajud_sub"),
                    hasToggle: true,
                    iconTint: Color.Token.deepEmerald,
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
                Text(languageManager.localize("sign_out"))
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
        case ..<0.95: return languageManager.localize("font_small")
        case 0.95 ..< 1.1: return languageManager.localize("font_medium")
        case 1.1 ..< 1.22: return languageManager.localize("font_large")
        default: return languageManager.localize("font_extra_large")
        }
    }
}

struct AppLanguageSelectionSheet: View {
    @Binding var selectedLanguage: AppLanguage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        selectedLanguage = lang
                        dismiss()
                    } label: {
                        HStack {
                            Text(lang.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedLanguage == lang {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.Token.deepEmerald)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            .navigationTitle(AppLanguageManager.shared.localize("app_language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppLanguageManager.shared.localize("close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension View {
    func profileCardStyle() -> some View {
        background(Color.Token.pureWhite)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.Token.softGrey.opacity(0.5), lineWidth: 0.5)
            )
    }
}
