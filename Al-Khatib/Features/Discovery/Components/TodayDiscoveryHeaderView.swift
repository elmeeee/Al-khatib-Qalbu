//
//  TodayDiscoveryHeaderView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct TodayDiscoveryHeaderView: View {
    let hijriDate: String?
    let gregorianDate: String?
    let cityName: String?
    let avatarURL: URL?
    let isLoggingIn: Bool
    let onAccountTap: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                RotatingPrayerDateLabelView(hijri: hijriDate, gregorian: gregorianDate)

                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.system(size: 14))
                    Text(cityName ?? "")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .padding(.leading, 2)
                }
                .foregroundColor(Color.Token.deepEmerald)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(AlKhatibAccessibility.Today.location), \(cityName ?? "")")
            }

            Spacer()

            Button(action: onAccountTap) {
                TodayProfileAvatarButton(url: avatarURL, isLoggingIn: isLoggingIn)
            }
            .disabled(isLoggingIn)
            .alKhatibAccessibility(
                label: AlKhatibAccessibility.Today.account,
                hint: AlKhatibAccessibility.Today.accountHint
            )
        }
        .padding(.horizontal, TodayDiscoveryLayout.horizontalInset)
        .padding(.top, 16)
    }
}

struct TodayProfileAvatarButton: View {
    let url: URL?
    let isLoggingIn: Bool

    var body: some View {
        Group {
            if isLoggingIn {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(ProgressView().tint(Color.Token.deepEmerald))
            } else if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        fallbackIcon
                    case .empty:
                        ProgressView().tint(Color.Token.deepEmerald)
                    @unknown default:
                        fallbackIcon
                    }
                }
                .id(url)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.Token.deepEmerald.opacity(0.3), lineWidth: 1.5)
                )
            } else {
                fallbackIcon
            }
        }
    }

    private var fallbackIcon: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Color.Token.deepEmerald)
            )
    }
}
