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
    @AppStorage(ChapterReaderPreferences.translationIdKey) private var selectedTranslationId = ChapterReaderPreferences.defaultTranslationId
    @AppStorage(ChapterReaderPreferences.translationNameKey) private var selectedTranslationName = ""
    @AppStorage(PrayerCalculationMethod.storageKey)
    private var prayerMethodRaw = PrayerCalculationMethod.defaultMethod.rawValue

    @State private var vm: ProfileViewModel?
    @State private var isOAuthPresenting = false
    @State private var showingFontScaleSheet = false
    @State private var showingTranslatorSheet = false

    private let tealThemeColor = Color.Token.teal
    private let slateBlueColor = Color.Token.slate500

    var body: some View {
        ZStack {
            Color.Token.screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader("General")
                        
                        VStack(spacing: 0) {
                            Button {
                                showingFontScaleSheet = true
                            } label: {
                                ProfileRow(
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
                        .background(Color.Theme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader("Prayer Setting")

                        VStack(spacing: 0) {
                            NavigationLink {
                                PrayerCalculationSettingsView()
                            } label: {
                                ProfileRow(
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

                            ProfileRow(
                                icon: "book.pages",
                                title: "Show Translation",
                                subtitle: "English",
                                hasToggle: true,
                                isOn: $showTranslation
                            )

                            Divider().padding(.leading, 64)

                            Button {
                                showingTranslatorSheet = true
                            } label: {
                                ProfileRow(
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
                        .background(Color.Theme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader("Notifications")

                        VStack(spacing: 0) {
                            ProfileRow(
                                icon: "bell",
                                title: "Prayer times",
                                subtitle: "Fajr, Dhuhr, Asr, Maghrib & Isha",
                                hasToggle: true,
                                isOn: $adzanEnabled
                            )

                            Divider().padding(.leading, 64)

                            ProfileRow(
                                icon: "bell.badge",
                                title: "Imsak",
                                subtitle: "Reminder before Fajr while fasting",
                                hasToggle: true,
                                isOn: $imsakEnabled
                            )

                            Divider().padding(.leading, 64)

                            ProfileRow(
                                icon: "moon",
                                title: "Midnight",
                                subtitle: "Halfway through the night",
                                hasToggle: true,
                                isOn: $midnightEnabled
                            )

                            Divider().padding(.leading, 64)

                            ProfileRow(
                                icon: "moon.stars",
                                title: "First third of night",
                                subtitle: "Early night rest reminder",
                                hasToggle: true,
                                isOn: $firstThirdEnabled
                            )

                            Divider().padding(.leading, 64)

                            ProfileRow(
                                icon: "sparkles",
                                title: "Last third (Tahajud)",
                                subtitle: "Best time for night prayer",
                                hasToggle: true,
                                isOn: $tahajudEnabled
                            )
                        }
                        .background(Color.Theme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
                    }

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
            guard let container, vm == nil else { return }
            vm = ProfileViewModel(container: container)
        }
        .task {
            guard let container else { return }
            if vm == nil { vm = ProfileViewModel(container: container) }
            await vm?.hydrateFromCacheIfNeeded()
            syncVerseStateProfile()
            await vm?.fetchProfile()
            syncVerseStateProfile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserProfileDidUpdate)) { _ in
            Task { @MainActor in
                await vm?.hydrateFromCacheIfNeeded()
                syncVerseStateProfile()
            }
        }
        .sheet(isPresented: $showingFontScaleSheet) {
            FontScaleSheet(fontScale: $fontScale)
        }
        .sheet(isPresented: $showingTranslatorSheet) {
            if let container {
                TranslatorSelectionSheet(
                    selectedTranslationId: $selectedTranslationId,
                    selectedTranslationName: $selectedTranslationName,
                    contentRepository: container.content
                )
            }
        }
        .onChange(of: selectedTranslationId) { _, _ in
            ChapterReaderPreferences.notifyTranslationDidChange()
        }
        .onChange(of: adzanEnabled) { _, _ in PrayerNotificationPreferences.notifyDidChange() }
        .onChange(of: imsakEnabled) { _, _ in PrayerNotificationPreferences.notifyDidChange() }
        .onChange(of: midnightEnabled) { _, _ in PrayerNotificationPreferences.notifyDidChange() }
        .onChange(of: firstThirdEnabled) { _, _ in PrayerNotificationPreferences.notifyDidChange() }
        .onChange(of: tahajudEnabled) { _, _ in PrayerNotificationPreferences.notifyDidChange() }
        .onReceive(NotificationCenter.default.publisher(for: .qfOAuthWebAuthStateDidChange)) { _ in
            isOAuthPresenting = container?.oauth.isWebAuthInProgress == true
            guard isOAuthPresenting == false else { return }
            Task { @MainActor in
                if await container?.userSession.hasUserAccessToken() == true {
                    await vm?.fetchProfile(force: true)
                    syncVerseStateProfile()
                } else {
                    vm?.profile = nil
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                guard container?.oauth.isWebAuthInProgress != true else { return }
                guard let container else { return }
                if await container.userSession.hasUserAccessToken() {
                    await vm?.fetchProfile(force: true)
                    syncVerseStateProfile()
                } else {
                    vm?.profile = nil
                    vm?.isLoading = false
                }
            }
        }
    }

    private var headerSection: some View {
        Group {
            if let vm {
                bindableHeaderSection(vm: vm)
            } else {
                headerSectionWithoutViewModel
            }
        }
    }

    @ViewBuilder
    private func bindableHeaderSection(vm: ProfileViewModel) -> some View {
        @Bindable var vm = vm
        if let profile = vm.profile {
            signedInHeader(profile: profile)
        } else if verseState?.isLoggedIn == true {
            signedInHeaderFromVerseState
        } else if vm.isLoading {
            headerLoadingCard
        } else {
            headerSignInCard
        }
    }

    private var headerSectionWithoutViewModel: some View {
        Group {
            if verseState?.isLoggedIn == true {
                signedInHeaderFromVerseState
            } else {
                headerSignInCard
            }
        }
    }

    private func signedInHeader(profile: UserProfilePayload) -> some View {
        HStack(spacing: 16) {
            profileAvatar(url: profile.preferredAvatarURL)

            VStack(alignment: .leading, spacing: 6) {
                Text(profile.displayTitle)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.Token.slate800)

                let country = profile.country ?? ""
                if !country.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 11, weight: .semibold))
                        Text(country)
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(tealThemeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(tealThemeColor.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var signedInHeaderFromVerseState: some View {
        HStack(spacing: 16) {
            profileAvatar(url: verseState?.userAvatarURL)

            VStack(alignment: .leading, spacing: 6) {
                Text(verseState?.userDisplayName ?? "Profile")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.Token.slate800)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var headerLoadingCard: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Theme.softGrey.opacity(0.35))
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.Theme.softGrey.opacity(0.35))
                    .frame(width: 140, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.Theme.softGrey.opacity(0.25))
                    .frame(width: 90, height: 10)
            }
            Spacer()
            ProgressView().tint(tealThemeColor)
        }
        .padding(16)
        .background(Color.Theme.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
    }

    private var headerSignInCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(tealThemeColor)
                .frame(width: 52, height: 52)
                .background(tealThemeColor.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Sync Reflections")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.Token.slate800)
                Text("Sign in to back up progress.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                Task {
                    await vm?.signIn()
                    syncVerseStateProfile()
                }
            } label: {
                HStack(spacing: 6) {
                    if isOAuthPresenting {
                        ProgressView().tint(.white)
                    }
                    Text("Sign In")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(tealThemeColor)
                .clipShape(Capsule())
                .shadow(color: tealThemeColor.opacity(0.2), radius: 4, y: 2)
            }
            .buttonStyle(PillPressStyle())
            .disabled(isOAuthPresenting)
            .alKhatibAccessibility(
                label: AlKhatibAccessibility.Profile.signIn,
                hint: "Back up reflections and sync your profile"
            )
        }
        .padding(16)
        .background(Color.Theme.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
    }

    private func profileAvatar(url: URL?) -> some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure, .empty:
                        defaultProfileAvatar
                    @unknown default:
                        defaultProfileAvatar
                    }
                }
                .id(url)
            } else {
                defaultProfileAvatar
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
    }

    private var defaultProfileAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 72))
            .foregroundColor(tealThemeColor.opacity(0.85))
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(slateBlueColor)
            .padding(.leading, 4)
            .accessibilityAddTraits(.isHeader)
    }

    private var logOutButton: some View {
        Button {
            Task {
                await vm?.signOut()
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
        if let vm {
            return vm.profile != nil || verseState?.isLoggedIn == true
        }
        return verseState?.isLoggedIn == true
    }

    private func syncVerseStateProfile() {
        guard let profile = vm?.profile else { return }
        verseState?.applyProfile(profile)
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

private struct ProfileRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let hasToggle: Bool
    @Binding var isOn: Bool

    private let tealThemeColor = Color.Token.teal

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.Theme.softGrey.opacity(0.7), lineWidth: 1)
                    .background(Color.Theme.pureWhite)
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(tealThemeColor)
            }

            if hasToggle == false {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.Token.slate800)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if hasToggle {
                Toggle(isOn: $isOn) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.Token.slate800)
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .tint(tealThemeColor)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.Theme.softGrey)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: hasToggle ? .ignore : .combine)
        .accessibilityLabel(
            hasToggle
                ? AlKhatibAccessibility.Profile.toggle(title, subtitle: subtitle, isOn: isOn)
                : "\(title). \(subtitle)"
        )
    }
}

private struct FontScaleSheet: View {
    @Binding var fontScale: Double
    @Environment(\.dismiss) private var dismiss

    private let tealThemeColor = Color.Token.teal
    private let fontScaleRange: ClosedRange<Double> = 0.85 ... 1.35

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Sample Arabic Typography")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                // Live Scale Text Preview
                VStack(spacing: 12) {
                    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                        .font(.system(size: 26 * fontScale, weight: .semibold, design: .serif))
                        .foregroundColor(Color.Theme.deepEmerald)
                        .multilineTextAlignment(.center)
                    
                    Text("In the name of Allah, the Entirely Merciful, the Especially Merciful.")
                        .font(.system(size: 14 * fontScale))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(Color.Theme.lightGrey, in: RoundedRectangle(cornerRadius: 16))

                // Custom Slider
                HStack(spacing: 16) {
                    Text("A")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)

                    Slider(value: $fontScale, in: fontScaleRange, step: 0.05)
                        .tint(tealThemeColor)

                    Text("A")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)

                // Current Scale Label Badge
                Text(fontScaleLabel)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(tealThemeColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(tealThemeColor.opacity(0.1))
                    .clipShape(Capsule())

                // Done Button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(tealThemeColor)
                        .clipShape(Capsule())
                }
                .padding(.top, 12)
            }
            .padding(24)
            .navigationTitle("Font Size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .tint(tealThemeColor)
                }
            }
        }
        .presentationDetents([.fraction(0.55)])
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

private struct TranslatorSelectionSheet: View {
    @Binding var selectedTranslationId: Int
    @Binding var selectedTranslationName: String

    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    @State private var translations: [QFTranslation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    let contentRepository: QuranContentRepository

    private let tealThemeColor = Color.Token.teal

    var filteredTranslations: [QFTranslation] {
        if searchQuery.isEmpty {
            return translations
        } else {
            return translations.filter { trans in
                trans.authorName.localizedCaseInsensitiveContains(searchQuery) ||
                trans.name.localizedCaseInsensitiveContains(searchQuery) ||
                trans.languageName.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Token.screenBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search translators or languages...", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.Theme.pureWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    if isLoading {
                        Spacer()
                        ProgressView("Loading translators...")
                            .tint(tealThemeColor)
                        Spacer()
                    } else if let errorMessage {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 44))
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            Button("Try Again") {
                                Task { await loadTranslations() }
                            }
                            .tint(tealThemeColor)
                            .buttonStyle(.borderedProminent)
                        }
                        Spacer()
                    } else {
                        List(filteredTranslations) { trans in
                            Button {
                                selectedTranslationId = trans.id
                                selectedTranslationName = trans.authorName.isEmpty ? trans.name : trans.authorName
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(trans.authorName.isEmpty ? trans.name : trans.authorName)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(Color.Token.slate800)
                                        Text("\(trans.languageName.capitalized) · \(trans.name)")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if trans.id == selectedTranslationId {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(tealThemeColor)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.Theme.pureWhite)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Select Translator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .tint(tealThemeColor)
                }
            }
            .task {
                await loadTranslations()
            }
        }
    }

    private func loadTranslations() async {
        isLoading = true
        errorMessage = nil
        do {
            let res = try await contentRepository.getTranslations()
            // Sort English first, then others alphabetically by language and author
            self.translations = res.translations.sorted { a, b in
                if a.languageName == "english" && b.languageName != "english" {
                    return true
                }
                if b.languageName == "english" && a.languageName != "english" {
                    return false
                }
                if a.languageName == b.languageName {
                    return a.authorName < b.authorName
                }
                return a.languageName < b.languageName
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
