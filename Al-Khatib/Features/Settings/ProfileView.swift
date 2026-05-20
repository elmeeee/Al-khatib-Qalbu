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
    @Environment(\.appContainer) private var container
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("chapterReaderFontScale") private var fontScale = 1.0
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("chapterReaderShowTranslation") private var showTranslation = true
    @AppStorage("adzanNotificationsEnabled") private var adzanEnabled = true
    @AppStorage("imsakNotificationsEnabled") private var imsakEnabled = true
    @AppStorage("tahajudNotificationsEnabled") private var tahajudEnabled = true
    @AppStorage("chapterReaderTranslationId") private var selectedTranslationId = 131
    @AppStorage("chapterReaderTranslationName") private var selectedTranslationName = "Dr. Mustafa Khattab"

    @State private var vm: ProfileViewModel?
    @State private var isOAuthPresenting = false
    @State private var showingFontScaleSheet = false
    @State private var showingTranslatorSheet = false

    private let tealThemeColor = Color(hex: "#0D9488")
    private let slateBlueColor = Color(hex: "#64748B")

    var body: some View {
        ZStack {
            // Screen Background
            Color(hex: "#F8FAFC").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection

                    // General Section
                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader("General")
                        
                        VStack(spacing: 0) {
                            // Font Size Row
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

                            Divider().padding(.leading, 64)

                            ProfileRow(
                                icon: "moon",
                                title: "Dark Theme",
                                subtitle: "Switch to a dark color scheme",
                                hasToggle: true,
                                isOn: $isDarkMode
                            )
                        }
                        .background(Color.Theme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
                    }

                    // Prayer Setting Section
                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader("Prayer Setting")

                        VStack(spacing: 0) {
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

                            Divider().padding(.leading, 64)

                            // Adzan Notification Row
                            ProfileRow(
                                icon: "bell",
                                title: "Adzan Notification",
                                subtitle: "s",
                                hasToggle: true,
                                isOn: $adzanEnabled
                            )

                            Divider().padding(.leading, 64)

                            // Imsak Notification Row
                            ProfileRow(
                                icon: "bell.badge",
                                title: "Imsak Notification",
                                subtitle: "Default",
                                hasToggle: true,
                                isOn: $imsakEnabled
                            )

                            Divider().padding(.leading, 64)

                            // Tahajud Notification Row
                            ProfileRow(
                                icon: "sparkles",
                                title: "Tahajud Notification",
                                subtitle: "Default",
                                hasToggle: true,
                                isOn: $tahajudEnabled
                            )
                        }
                        .background(Color.Theme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
                    }

                    if vm?.profile != nil {
                        logOutButton
                    } else {
                        signInCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(preferSystemNavigationTitle ? "Profile" : "")
        .navigationBarTitleDisplayMode(preferSystemNavigationTitle ? .large : .inline)
        .task {
            guard let container else { return }
            if vm == nil { vm = ProfileViewModel(container: container) }
            await vm?.fetchProfile()
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
        .onReceive(NotificationCenter.default.publisher(for: .qfOAuthWebAuthStateDidChange)) { _ in
            isOAuthPresenting = container?.oauth.isWebAuthInProgress == true
            guard isOAuthPresenting == false else { return }
            Task { @MainActor in
                if await container?.userSession.hasUserAccessToken() == true {
                    await vm?.fetchProfile(force: true)
                } else {
                    vm?.profile = nil
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                guard container?.oauth.isWebAuthInProgress != true else { return }
                if await container?.userSession.hasUserAccessToken() == true {
                    await vm?.fetchProfile(force: true)
                } else {
                    vm?.profile = nil
                }
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            profileAvatar

            VStack(alignment: .leading, spacing: 6) {
                Text(vm?.profile?.displayTitle ?? "")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#1E293B"))

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11, weight: .semibold))
                    Text(vm?.profile?.country ?? "Sumedang, West Java")
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

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var profileAvatar: some View {
        Group {
            if let url = vm?.profile?.preferredAvatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure, .empty:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(slateBlueColor)
            .padding(.leading, 4)
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
            .background(Color(hex: "#EF4444"))
            .clipShape(Capsule())
            .shadow(color: Color(hex: "#EF4444").opacity(0.2), radius: 8, y: 4)
        }
        .buttonStyle(PillPressStyle())
        .disabled(isOAuthPresenting)
        .opacity(isOAuthPresenting ? 0.5 : 1)
    }

    private var signInCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Sync Reflections & Journey")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#1E293B"))
                Text("Connect with Quran Reflect to back up reading stats, sync your profile, and share daily reflections.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            Button {
                Task { await vm?.signIn() }
            } label: {
                HStack(spacing: 8) {
                    if isOAuthPresenting {
                        ProgressView().tint(.white)
                    }
                    Text(isOAuthPresenting ? "Signing in…" : "Continue with Quran Reflect")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(tealThemeColor)
                .clipShape(Capsule())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.Theme.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
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

// MARK: - Premium Settings Row

private struct ProfileRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let hasToggle: Bool
    @Binding var isOn: Bool

    private let tealThemeColor = Color(hex: "#0D9488")

    var body: some View {
        HStack(spacing: 16) {
            // Icon Rounded Container
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.Theme.softGrey.opacity(0.7), lineWidth: 1)
                    .background(Color.Theme.pureWhite)
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(tealThemeColor)
            }

            // Title & Subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#1E293B"))
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Optional Switch or Chevron
            if hasToggle {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
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
    }
}

// MARK: - Premium Font Scale Picker Sheet

private struct FontScaleSheet: View {
    @Binding var fontScale: Double
    @Environment(\.dismiss) private var dismiss

    private let tealThemeColor = Color(hex: "#0D9488")
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

// MARK: - Premium Translator Picker Sheet

private struct TranslatorSelectionSheet: View {
    @Binding var selectedTranslationId: Int
    @Binding var selectedTranslationName: String

    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    @State private var translations: [QFTranslation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    let contentRepository: QuranContentRepository

    private let tealThemeColor = Color(hex: "#0D9488")

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
                Color(hex: "#F8FAFC").ignoresSafeArea()

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
                                            .foregroundColor(Color(hex: "#1E293B"))
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
