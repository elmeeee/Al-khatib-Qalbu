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
    @AppStorage(PrayerCalculationMethod.storageKey)
    private var prayerMethodRaw = PrayerCalculationMethod.defaultMethod.rawValue
    @State private var vm: ProfileViewModel?
    @State private var isOAuthPresenting = false

    private var selectedPrayerMethod: PrayerCalculationMethod {
        PrayerCalculationMethod(rawValue: prayerMethodRaw) ?? .muhammadiyah
    }

    var body: some View {
        ZStack {
            Color.Theme.offWhite.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if preferSystemNavigationTitle == false {
                        pageTitle
                    }

                    mainCard

                    if vm?.profile != nil {
                        settingsCard
                    }

                    footerActions
                }
                .padding(.horizontal, 20)
                .padding(.top, preferSystemNavigationTitle ? 8 : 0)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(preferSystemNavigationTitle ? "Profile" : "")
        .navigationBarTitleDisplayMode(preferSystemNavigationTitle ? .large : .inline)
        .task {
            guard let container else { return }
            if vm == nil { vm = ProfileViewModel(container: container) }
            await vm?.fetchProfile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfOAuthWebAuthStateDidChange)) { _ in
            isOAuthPresenting = container?.oauth.isWebAuthInProgress == true
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                guard container?.oauth.isWebAuthInProgress != true else { return }
                await vm?.fetchProfile()
            }
        }
        .toolbar {
            if preferSystemNavigationTitle {
                ToolbarItem(placement: .topBarTrailing) {
                    if vm?.isLoading == true || isOAuthPresenting {
                        ProgressView()
                            .tint(Color.Theme.deepEmerald)
                    }
                }
            }
        }
    }

    // MARK: - Layout

    private var pageTitle: some View {
        HStack {
            Text("Profile")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.Theme.deepEmerald)
            Spacer()
            if vm?.isLoading == true || isOAuthPresenting {
                ProgressView()
                    .tint(Color.Theme.deepEmerald)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var mainCard: some View {
        VStack(spacing: 0) {
            if let profile = vm?.profile {
                signedInHeader(profile)
            } else if vm == nil || (vm?.isLoading == true && isOAuthPresenting == false) {
                loadingHeader
            } else {
                signedOutHeader
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.Theme.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.Theme.softGrey.opacity(0.85), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: 4)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                NavigationLink {
                    PrayerCalculationSettingsView()
                } label: {
                    ProfileSettingsRow(
                        icon: "clock.fill",
                        title: "Prayer calculation",
                        subtitle: selectedPrayerMethod.subtitle,
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
            .background(Color.Theme.pureWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.Theme.softGrey.opacity(0.85), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var footerActions: some View {
        if vm?.profile != nil {
            Button {
                Task {
                    await vm?.signOut()
                    hasCompletedOnboarding = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign out")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.Theme.pureWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.Theme.softGrey.opacity(0.85), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(isOAuthPresenting)
            .opacity(isOAuthPresenting ? 0.5 : 1)
        }
    }

    // MARK: - Signed in

    private func signedInHeader(_ profile: UserProfilePayload) -> some View {
        VStack(spacing: 0) {
            profileBanner

            VStack(spacing: 18) {
                profileAvatar(profile)
                    .overlay(alignment: .bottomTrailing) {
                        verifiedBadge(isVerified: profile.verified == true)
                            .offset(x: 6, y: 6)
                    }
                    .offset(y: -44)
                    .padding(.bottom, -44)

                VStack(spacing: 6) {
                    Text(profile.displayTitle)
                        .font(.title2.bold())
                        .foregroundStyle(Color.Theme.deepEmerald)
                        .multilineTextAlignment(.center)

                    if let username = profile.username, username.isEmpty == false {
                        Text("@\(username)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.Theme.deepEmerald.opacity(0.55))
                    }

                    if let bio = profile.bio, bio.isEmpty == false {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }

                    if let country = profile.country, country.isEmpty == false {
                        Label(country, systemImage: "globe")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 20)

                if hasStats(profile) {
                    statsRow(profile)
                        .padding(.horizontal, 16)
                }

                memberSinceLabel(profile)
                    .padding(.bottom, 20)
            }
        }
    }

    private var profileBanner: some View {
        LinearGradient(
            colors: [
                Color.Theme.deepEmerald,
                Color.Theme.deepEmerald.opacity(0.82)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 100)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(Color.white.opacity(0.2))
                .padding(16)
        }
    }

    private func statsRow(_ profile: UserProfilePayload) -> some View {
        HStack(spacing: 0) {
            if let posts = profile.postsCount {
                statCell(value: posts, label: "Posts")
            }
            if let followers = profile.followersCount {
                statCell(value: followers, label: "Followers")
            }
            if let likes = profile.likesCount {
                statCell(value: likes, label: "Likes")
            }
        }
        .padding(.vertical, 14)
        .background(Color.Theme.lightGrey.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func statCell(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text(formattedCount(value))
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.Theme.deepEmerald)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func memberSinceLabel(_ profile: UserProfilePayload) -> some View {
        if let year = profile.joiningYear {
            Text("Member since \(year)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func hasStats(_ profile: UserProfilePayload) -> Bool {
        profile.postsCount != nil || profile.followersCount != nil || profile.likesCount != nil
    }

    private func formattedCount(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }
        if value >= 10_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }

    // MARK: - Loading

    private var loadingHeader: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(Color.Theme.lightGrey)
                .frame(height: 100)

            VStack(spacing: 12) {
                SkeletonCircleDot(size: 96)
                    .offset(y: -48)
                    .padding(.bottom, -48)

                SkeletonBar(width: 160, height: 22, cornerRadius: 6)
                SkeletonBar(width: 100, height: 14, cornerRadius: 6)

                HStack(spacing: 12) {
                    SkeletonBar(width: nil, height: 52, cornerRadius: 12)
                    SkeletonBar(width: nil, height: 52, cornerRadius: 12)
                    SkeletonBar(width: nil, height: 52, cornerRadius: 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Signed out

    private var signedOutHeader: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(Color.Theme.deepEmerald.opacity(0.45))
                    .padding(.top, 28)

                Text("Sign in to Al-Khatib")
                    .font(.title3.bold())
                    .foregroundStyle(Color.Theme.deepEmerald)

                Text("Sync reflections, reading progress, and your Quran Reflect profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            VStack(alignment: .leading, spacing: 12) {
                signInBenefit(icon: "book.closed.fill", text: "Track where you left off in each surah")
                signInBenefit(icon: "bubble.left.and.text.bubble.right.fill", text: "Post reflections to the community")
                signInBenefit(icon: "flame.fill", text: "Keep your reading streak alive")
            }
            .padding(.horizontal, 4)

            if let error = vm?.errorMessage, error != "missing_user_session" {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await vm?.signIn() }
            } label: {
                HStack(spacing: 8) {
                    if isOAuthPresenting {
                        ProgressView().tint(.white)
                    }
                    Text(isOAuthPresenting ? "Signing in…" : "Continue with Quran Reflect")
                }
            }
            .buttonStyle(.primaryFlat)
            .disabled(isOAuthPresenting)
            .padding(.horizontal, 4)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
    }

    private func signInBenefit(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.Theme.deepEmerald)
                .frame(width: 32, height: 32)
                .background(Color.Theme.deepEmerald.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private func profileAvatar(_ profile: UserProfilePayload) -> some View {
        Group {
            if let url = profile.preferredAvatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        profilePlaceholderIcon
                    case .empty:
                        ProgressView().tint(Color.Theme.deepEmerald)
                    @unknown default:
                        profilePlaceholderIcon
                    }
                }
            } else {
                profilePlaceholderIcon
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Color.Theme.pureWhite, lineWidth: 4)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
    }

    private var profilePlaceholderIcon: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 40, weight: .medium))
            .foregroundStyle(Color.Theme.deepEmerald.opacity(0.35))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.Theme.lightGrey)
    }

    private func verifiedBadge(isVerified: Bool) -> some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 28))
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                isVerified ? Color.Theme.pureWhite : Color.Theme.softGrey,
                isVerified ? Color.Theme.deepEmerald : Color.Theme.softGrey.opacity(0.85)
            )
            .background {
                Circle()
                    .fill(Color.Theme.pureWhite)
                    .frame(width: 34, height: 34)
            }
            .accessibilityLabel(isVerified ? "Verified account" : "Not verified")
    }
}

// MARK: - Settings row

private struct ProfileSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var showsChevron: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.Theme.deepEmerald)
                .frame(width: 40, height: 40)
                .background(Color.Theme.deepEmerald.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.Theme.softGrey)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}
