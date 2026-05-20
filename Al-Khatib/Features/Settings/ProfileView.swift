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

    private let avatarSize: CGFloat = 120
    private let verifiedBadgeSize: CGFloat = 34

    var body: some View {
        ZStack {
            Color.Theme.offWhite.ignoresSafeArea()

            VStack(spacing: 0) {
                if preferSystemNavigationTitle == false {
                    accountTopBar
                }

                Group {
                    if let profile = vm?.profile {
                        signedInContent(profile)
                    } else if vm == nil || vm?.isLoading == true || vm?.authBusy == true {
                        profileLoadingPlaceholder
                    } else {
                        signedOutContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                profileSettingsLinks
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)

                signOutFooter
            }
        }
        .task {
            guard let container else { return }
            if vm == nil { vm = ProfileViewModel(container: container) }
            await vm?.fetchProfile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .qfUserSessionDidChange)) { _ in
            Task { @MainActor in
                await vm?.fetchProfile()
            }
        }
        .toolbar {
            if preferSystemNavigationTitle {
                ToolbarItem(placement: .topBarTrailing) {
                    if vm?.isLoading == true || vm?.authBusy == true {
                        ProgressView()
                            .tint(Color.Theme.deepEmerald)
                    }
                }
            }
        }
    }

    private var accountTopBar: some View {
        HStack {
            Text("Account")
                .font(.largeTitle.bold())
                .foregroundColor(Color.Theme.deepEmerald)
            Spacer()
            if vm?.isLoading == true || vm?.authBusy == true {
                ProgressView()
                    .tint(Color.Theme.deepEmerald)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var signOutFooter: some View {
        VStack(spacing: 16) {
            Button {
                Task {
                    await vm?.signOut()
                    hasCompletedOnboarding = true
                }
            } label: {
                Text("Sign out")
            }
            .buttonStyle(.ghostFlat)
            .disabled(vm?.authBusy == true || vm?.profile == nil)
            .opacity(vm?.profile == nil ? 0.45 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    private func signedInContent(_ profile: UserProfilePayload) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            profileHero(profile)

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 32)
    }

    private var profileSettingsLinks: some View {
        VStack(spacing: 10) {
            NavigationLink {
                PrayerCalculationSettingsView()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "clock.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.Theme.deepEmerald)
                        .frame(width: 36, height: 36)
                        .background(Color.Theme.deepEmerald.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prayer times")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(
                            (PrayerCalculationMethod(rawValue: prayerMethodRaw) ?? .muhammadiyah).subtitle
                        )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.Theme.softGrey)
                }
                .padding(14)
                .background(Color.Theme.pureWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.Theme.softGrey.opacity(0.9), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func profileHero(_ profile: UserProfilePayload) -> some View {
        VStack(spacing: 20) {
            ZStack(alignment: .bottomTrailing) {
                profileAvatar(profile)
                    .frame(width: avatarSize, height: avatarSize)

                verifiedBadge(isVerified: profile.verified == true)
                    .offset(x: 4, y: 4)
            }

            VStack(spacing: 6) {
                Text(profile.displayTitle)
                    .font(.title2.bold())
                    .foregroundColor(Color.Theme.deepEmerald)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if let username = profile.username, username.isEmpty == false {
                    Text("@\(username)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.Theme.deepEmerald.opacity(0.55))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func profileAvatar(_ profile: UserProfilePayload) -> some View {
        Group {
            if let url = profile.preferredAvatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        profilePlaceholderIcon
                    case .empty:
                        ProgressView()
                            .tint(Color.Theme.deepEmerald)
                    @unknown default:
                        profilePlaceholderIcon
                    }
                }
            } else {
                profilePlaceholderIcon
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Color.Theme.deepEmerald.opacity(0.2), lineWidth: 2)
        }
        .background {
            Circle()
                .fill(Color.Theme.pureWhite)
        }
    }

    private var profilePlaceholderIcon: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 44, weight: .medium))
            .foregroundStyle(Color.Theme.deepEmerald.opacity(0.35))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.Theme.lightGrey)
    }

    private func verifiedBadge(isVerified: Bool) -> some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: verifiedBadgeSize))
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                isVerified ? Color.Theme.pureWhite : Color.Theme.softGrey,
                isVerified ? Color.Theme.deepEmerald : Color.Theme.softGrey.opacity(0.85)
            )
            .background {
                Circle()
                    .fill(Color.Theme.offWhite)
                    .frame(width: verifiedBadgeSize + 6, height: verifiedBadgeSize + 6)
            }
            .accessibilityLabel(isVerified ? "Verified account" : "Not verified")
    }

    private var profileLoadingPlaceholder: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)

            ZStack(alignment: .bottomTrailing) {
                SkeletonCircleDot(size: avatarSize)
                SkeletonCircleDot(size: verifiedBadgeSize)
                    .offset(x: 4, y: 4)
            }

            VStack(spacing: 10) {
                SkeletonBar(width: 160, height: 22, cornerRadius: 6)
                SkeletonBar(width: 100, height: 14, cornerRadius: 6)
            }

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 32)
    }

    private var signedOutContent: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)

            Image(systemName: "person.crop.circle")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Color.Theme.deepEmerald.opacity(0.35))

            VStack(spacing: 8) {
                Text("Sign in to your account")
                    .font(.title3.bold())
                    .foregroundColor(Color.Theme.deepEmerald)
                if let error = vm?.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }

            Button {
                Task { await vm?.signIn() }
            } label: {
                HStack(spacing: 8) {
                    if vm?.authBusy == true {
                        ProgressView().tint(.white)
                    }
                    Text(vm?.authBusy == true ? "Signing in…" : "Sign in")
                }
            }
            .buttonStyle(.primaryFlat)
            .disabled(vm?.authBusy == true)
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 32)
    }
}
