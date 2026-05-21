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

    private func signedInHeader(profile: UserProfilePayload) -> some View {
        HStack(spacing: 16) {
            ProfileAvatarView(url: profile.preferredAvatarURL, size: 80)

            VStack(alignment: .leading, spacing: 6) {
                Text(profile.displayTitle)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.Token.slate800)

                if let country = profile.country, country.isEmpty == false {
                    countryChip(country)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func signedInFallbackHeader(name: String, avatarURL: URL?) -> some View {
        HStack(spacing: 16) {
            ProfileAvatarView(url: avatarURL, size: 80)
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.Token.slate800)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var loadingHeader: some View {
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
            ProgressView().tint(Color.Token.teal)
        }
        .padding(16)
        .background(Color.Theme.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
    }

    private var signInHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.Token.teal)
                .frame(width: 52, height: 52)
                .background(Color.Token.teal.opacity(0.1))
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

            Button(action: onSignIn) {
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
                .background(Color.Token.teal)
                .clipShape(Capsule())
                .shadow(color: Color.Token.teal.opacity(0.2), radius: 4, y: 2)
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

    private func countryChip(_ country: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 11, weight: .semibold))
            Text(country)
                .font(.system(size: 12, weight: .medium))
            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundColor(Color.Token.teal)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.Token.teal.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct ProfileAvatarView: View {
    let url: URL?
    var size: CGFloat = 80

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
        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
    }

    private var placeholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: size * 0.9))
            .foregroundColor(Color.Token.teal.opacity(0.85))
    }
}
