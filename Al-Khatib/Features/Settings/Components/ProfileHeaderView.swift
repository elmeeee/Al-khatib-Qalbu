//
//  ProfileHeaderView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ProfileHeaderView: View {
    let profile: UserProfilePayload?
    let fallbackName: String?
    let fallbackAvatarURL: URL?
    let isLoading: Bool
    let isOAuthPresenting: Bool
    let onSignIn: () -> Void

    var body: some View {
        Group {
            if let profile {
                signedInHeader(profile: profile)
            } else if let fallbackName, fallbackName.isEmpty == false {
                signedInFallbackHeader(name: fallbackName, avatarURL: fallbackAvatarURL)
            } else if isLoading {
                loadingHeader
            } else {
                signInHeader
            }
        }
    }

    // ── Signed-in (full profile) ─────────────────────────────────────────
    private func signedInHeader(profile: UserProfilePayload) -> some View {
        profileCard {
            HStack(alignment: .top, spacing: 14) {
                ProfileAvatarView(url: profile.preferredAvatarURL, size: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.displayTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.Token.deepEmerald)
                        .lineLimit(1)

                    if let country = profile.country, country.isEmpty == false {
                        countryChip(country)
                    }

                    // Stats row
                    let stats = makeStats(profile)
                    if stats.isEmpty == false {
                        HStack(spacing: 4) {
                            ForEach(Array(stats.enumerated()), id: \.offset) { idx, stat in
                                HStack(spacing: 2) {
                                    Text("\(stat.value)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Color.Token.deepEmerald)
                                    Text(stat.label)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.Token.slate500)
                                }

                                if idx < stats.count - 1 {
                                    Text("·")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.Token.softGrey)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // ── Fallback (token session, no full profile) ─────────────────────────
    private func signedInFallbackHeader(name: String, avatarURL: URL?) -> some View {
        profileCard {
            HStack(alignment: .center, spacing: 14) {
                ProfileAvatarView(url: avatarURL, size: 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.Token.deepEmerald)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // ── Loading skeleton ──────────────────────────────────────────────────
    private var loadingHeader: some View {
        profileCard {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.Token.softGrey.opacity(0.4))
                    .frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.Token.softGrey.opacity(0.45))
                        .frame(width: 140, height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.Token.softGrey.opacity(0.3))
                        .frame(width: 90, height: 10)
                }
                Spacer()
                ProgressView().tint(Color.Token.teal)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .redacted(reason: .placeholder)
        }
    }

    // ── Sign-in CTA ────────────────────────────────────────────────────────
    private var signInHeader: some View {
        profileCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.Token.teal.opacity(0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color.Token.teal.opacity(0.75))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLanguageManager.shared.localize("sync_reflections"))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.Token.deepEmerald)
                    Text(AppLanguageManager.shared.localize("sign_in_prompt"))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.Token.slate500)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(action: onSignIn) {
                    Group {
                        if isOAuthPresenting {
                            ProgressView().tint(.white)
                        } else {
                            Text(AppLanguageManager.shared.localize("sign_in"))
                                .font(.system(size: 13, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(
                            colors: [Color.Token.teal, Color.Token.tealDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.Token.teal.opacity(0.25), radius: 6, y: 3)
                }
                .buttonStyle(PillPressStyle())
                .disabled(isOAuthPresenting)
                .alKhatibAccessibility(
                    label: AlKhatibAccessibility.Profile.signIn,
                    hint: "Back up reflections and sync your profile"
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // ── Card container with gradient top bar ──────────────────────────────
    @ViewBuilder
    private func profileCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) {
            // Gradient top accent bar (matches Android)
            LinearGradient(
                colors: [Color.Token.deepEmerald, Color.Token.teal],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 3)

            content()
                .padding(.top, 16)
        }
        .background(Color.Token.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 12, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.Token.softGrey.opacity(0.5), lineWidth: 1)
        )
    }

    private func countryChip(_ country: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 10, weight: .semibold))
            Text(country)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(Color.Token.teal)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.Token.teal.opacity(0.1))
        .clipShape(Capsule())
    }

    private struct Stat { let label: String; let value: Int }

    private func makeStats(_ profile: UserProfilePayload) -> [Stat] {
        var stats: [Stat] = []
        if let posts = profile.postsCount { stats.append(Stat(label: "posts", value: posts)) }
        if let followers = profile.followersCount { stats.append(Stat(label: "followers", value: followers)) }
        if let likes = profile.likesCount { stats.append(Stat(label: "likes", value: likes)) }
        return stats
    }
}

// ─────────────────────────────────────────────────────────────────────────────

struct ProfileAvatarView: View {
    let url: URL?
    var size: CGFloat = 72

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure, .empty:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
                .id(url)
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.Token.teal, Color.Token.deepEmerald],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 6, y: 3)
    }

    private var placeholder: some View {
        ZStack {
            Circle().fill(Color.Token.teal.opacity(0.1))
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: size * 0.65))
                .foregroundColor(Color.Token.teal.opacity(0.8))
        }
    }
}
