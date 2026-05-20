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

                    appVersionLabel
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

    private var pageTitle: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Text("\u{2726}")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.Theme.gold)
                    Text("Profile")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.Theme.deepEmerald)
                }
                Spacer()
                if vm?.isLoading == true || isOAuthPresenting {
                    ProgressView()
                        .tint(Color.Theme.deepEmerald)
                }
            }

            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.Theme.gold, Color.Theme.gold.opacity(0.15)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 50, height: 3)
                Spacer()
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
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.Theme.deepEmerald.opacity(0.1), Color.Theme.softGrey.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: 4)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("\u{2726}")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.Theme.gold)
                Text("Settings")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
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
                    .stroke(
                        LinearGradient(
                            colors: [Color.Theme.deepEmerald.opacity(0.08), Color.Theme.softGrey.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.02), radius: 4, y: 2)
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
                        .font(.system(size: 14, weight: .semibold))
                    Text("Sign out")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.red.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.red.opacity(0.04))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.red.opacity(0.15), lineWidth: 1)
                }
            }
            .buttonStyle(PillPressStyle())
            .disabled(isOAuthPresenting)
            .opacity(isOAuthPresenting ? 0.5 : 1)
        }
    }

    private var appVersionLabel: some View {
        Group {
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Al-Khatib v\(version) (\(build))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.top, 4)
    }

    private func signedInHeader(_ profile: UserProfilePayload) -> some View {
        VStack(spacing: 0) {
            profileBanner

            VStack(spacing: 16) {
                profileAvatar(profile)
                    .overlay(alignment: .bottomTrailing) {
                        verifiedBadge(isVerified: profile.verified == true)
                            .offset(x: 6, y: 6)
                    }
                    .offset(y: -48)
                    .padding(.bottom, -48)

                VStack(spacing: 6) {
                    Text(profile.displayTitle)
                        .font(.title2.bold())
                        .foregroundStyle(Color.Theme.deepEmerald)
                        .multilineTextAlignment(.center)

                    if let username = profile.username, username.isEmpty == false {
                        Text("@\(username)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.Theme.deepEmerald.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.Theme.deepEmerald.opacity(0.06))
                            )
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
        ZStack {
            LinearGradient(
                colors: [
                    Color.Theme.deepEmerald,
                    Color(hex: "#0F766E"),
                    Color(hex: "#0A3D2E")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(45))
                            .offset(y: i.isMultiple(of: 2) ? -8 : 8)
                    }
                }
                .position(x: geo.size.width * 0.7, y: geo.size.height * 0.5)
            }

            HStack {
                Spacer()
                VStack {
                    Image(systemName: "sparkle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.Theme.gold.opacity(0.3))
                        .padding(.trailing, 50)
                        .padding(.top, 16)
                    Spacer()
                }
            }
        }
        .frame(height: 110)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 22,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 22,
                style: .continuous
            )
        )
    }

    private func statsRow(_ profile: UserProfilePayload) -> some View {
        HStack(spacing: 10) {
            if let posts = profile.postsCount {
                statCell(icon: "text.bubble.fill", value: posts, label: "Posts")
            }
            if let followers = profile.followersCount {
                statCell(icon: "person.2.fill", value: followers, label: "Followers")
            }
            if let likes = profile.likesCount {
                statCell(icon: "heart.fill", value: likes, label: "Likes")
            }
        }
    }

    private func statCell(icon: String, value: Int, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.Theme.deepEmerald.opacity(0.5))

            Text(formattedCount(value))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.Theme.deepEmerald, Color(hex: "#0F766E")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.Theme.deepEmerald.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.Theme.deepEmerald.opacity(0.06), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func memberSinceLabel(_ profile: UserProfilePayload) -> some View {
        if let year = profile.joiningYear {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .semibold))
                Text("Member since \(year)")
                    .font(.caption)
            }
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

    private var loadingHeader: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.Theme.deepEmerald.opacity(0.15), Color.Theme.lightGrey],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 110)

            VStack(spacing: 12) {
                ShimmerCircle(size: 96)
                    .offset(y: -48)
                    .padding(.bottom, -48)

                ShimmerBar(width: 160, height: 22)
                ShimmerBar(width: 100, height: 14)

                HStack(spacing: 10) {
                    ShimmerBar(width: nil, height: 72)
                    ShimmerBar(width: nil, height: 72)
                    ShimmerBar(width: nil, height: 72)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .padding(.bottom, 24)
        }
    }

    private var signedOutHeader: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.Theme.deepEmerald.opacity(0.04))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color.Theme.deepEmerald.opacity(0.06))
                        .frame(width: 72, height: 72)
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color.Theme.deepEmerald.opacity(0.55))
                }
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
                    Text(isOAuthPresenting ? "Signing in\u{2026}" : "Continue with Quran Reflect")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.Theme.deepEmerald, Color(hex: "#0F766E")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .foregroundColor(.white)
            }
            .buttonStyle(PillPressStyle())
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
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.Theme.deepEmerald.opacity(0.1), Color.Theme.deepEmerald.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

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
                .stroke(
                    LinearGradient(
                        colors: [Color.Theme.deepEmerald, Color.Theme.gold.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3.5
                )
        }
        .overlay {
            Circle()
                .stroke(Color.Theme.pureWhite, lineWidth: 3)
                .padding(3.5)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 4)
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
                isVerified ? Color.Theme.gold : Color.Theme.softGrey.opacity(0.85)
            )
            .background {
                Circle()
                    .fill(Color.Theme.pureWhite)
                    .frame(width: 34, height: 34)
            }
            .accessibilityLabel(isVerified ? "Verified account" : "Not verified")
    }
}

private struct ProfileSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var showsChevron: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.Theme.deepEmerald, Color(hex: "#0F766E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

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
                    .foregroundStyle(Color.Theme.gold.opacity(0.7))
            }
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}

private struct ShimmerBar: View {
    let width: CGFloat?
    let height: CGFloat
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.Theme.softGrey.opacity(0.2))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
    }
}

private struct ShimmerCircle: View {
    let size: CGFloat
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        Circle()
            .fill(Color.Theme.softGrey.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
    }
}
