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

    @State private var greetingPhase: CGFloat = 0

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 3..<12: return "Good Morning"
        case 12..<15: return "Good Afternoon"
        case 15..<18: return "Good Afternoon"
        case 18..<21: return "Good Evening"
        default: return "Good Night"
        }
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 3..<12: return "sunrise.fill"
        case 12..<18: return "sun.max.fill"
        case 18..<21: return "sunset.fill"
        default: return "moon.stars.fill"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                avatarButton

                VStack(alignment: .leading, spacing: 4) {
                    greetingRow
                    dateRow
                    locationRow
                }

                Spacer(minLength: 0)

                todayBadge
            }
            .padding(.horizontal, TodayDiscoveryLayout.horizontalInset)
            .padding(.top, 14)
            .padding(.bottom, 14)

            dividerLine
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                greetingPhase = 1
            }
        }
    }

    private var greetingRow: some View {
        HStack(spacing: 5) {
            Image(systemName: greetingIcon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.Token.goldDeep,
                            Color.Token.gold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating.speed(0.3))

            Text(greeting)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.Token.deepEmerald.opacity(0.7))
        }
    }

    private var dateRow: some View {
        RotatingPrayerDateLabelView(hijri: hijriDate, gregorian: gregorianDate)
    }

    private var locationRow: some View {
        HStack(spacing: 5) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.Token.deepEmerald, Color.Token.teal],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(cityName ?? "Locating…")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.Token.deepEmerald)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(AlKhatibAccessibility.Today.location), \(cityName ?? "")")
    }

    private var avatarButton: some View {
        Button(action: onAccountTap) {
            TodayProfileAvatarButton(url: avatarURL, isLoggingIn: isLoggingIn)
        }
        .disabled(isLoggingIn)
        .alKhatibAccessibility(
            label: AlKhatibAccessibility.Today.account,
            hint: AlKhatibAccessibility.Today.accountHint
        )
    }

    private var todayBadge: some View {
        HStack(spacing: 4) {
            Text("✦")
                .font(.system(size: 8))
                .foregroundStyle(Color.Token.gold)
            Text("Today")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.Token.deepEmerald)
                .tracking(0.3)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.Token.deepEmerald.opacity(0.06))
        )
        .overlay(
            Capsule()
                .stroke(Color.Token.deepEmerald.opacity(0.1), lineWidth: 0.5)
        )
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.Token.deepEmerald.opacity(0.0),
                        Color.Token.deepEmerald.opacity(0.08),
                        Color.Token.gold.opacity(0.1),
                        Color.Token.deepEmerald.opacity(0.08),
                        Color.Token.deepEmerald.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
            .padding(.horizontal, TodayDiscoveryLayout.horizontalInset)
    }
}

struct TodayProfileAvatarButton: View {
    let url: URL?
    let isLoggingIn: Bool

    var body: some View {
        Group {
            if isLoggingIn {
                avatarFrame {
                    ProgressView()
                        .tint(Color.Token.deepEmerald)
                        .scaleEffect(0.9)
                }
            } else if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        fallbackIcon
                    case .empty:
                        ProgressView()
                            .tint(Color.Token.deepEmerald)
                            .scaleEffect(0.9)
                    @unknown default:
                        fallbackIcon
                    }
                }
                .id(url)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.Token.deepEmerald.opacity(0.5),
                                    Color.Token.gold.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.Token.deepEmerald.opacity(0.1), radius: 4, y: 2)
            } else {
                fallbackIcon
            }
        }
    }

    @ViewBuilder
    private func avatarFrame<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Circle()
            .fill(Color.Token.pureWhite)
            .frame(width: 44, height: 44)
            .overlay(content())
            .overlay(
                Circle()
                    .stroke(Color.Token.softGrey, lineWidth: 1)
            )
    }

    private var fallbackIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.Token.deepEmerald.opacity(0.08),
                            Color.Token.deepEmerald.opacity(0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 44, height: 44)

            Image(systemName: "person.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.Token.deepEmerald, Color.Token.teal],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.Token.deepEmerald.opacity(0.2),
                            Color.Token.gold.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}
