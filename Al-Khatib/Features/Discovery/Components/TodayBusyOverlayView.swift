//
//  TodayBusyOverlayView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct TodayBusyOverlayView: View {
    let isPosting: Bool

    var body: some View {
        Color.black.opacity(0.18)
            .ignoresSafeArea()

        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.Theme.deepEmerald)
                .scaleEffect(1.1)
            Text(isPosting ? "Publishing your reflection..." : "Preparing your share...")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.Theme.deepEmerald)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.Theme.softGrey.opacity(0.8), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
    }
}

struct TodayStatusToastView: View {
    let message: String
    let isError: Bool

    var body: some View {
        Text(message)
            .font(.subheadline.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isError ? Color.red : Color.Theme.deepEmerald)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
            .padding(.top, 16)
    }
}
