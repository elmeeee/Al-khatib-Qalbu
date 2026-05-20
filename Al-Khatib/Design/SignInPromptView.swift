//
//  SignInPromptView.swift
//  Al-Khatib
//

import SwiftUI

/// Shown when a feature requires Quran Reflect sign-in.
struct SignInPromptView: View {
    let title: String
    let message: String
    var isLoading: Bool = false
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color.Theme.deepEmerald.opacity(0.45))

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(Color.Theme.deepEmerald)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            Button(action: onSignIn) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(isLoading ? "Signing in…" : "Continue with Quran Reflect")
                }
            }
            .buttonStyle(.primaryFlat)
            .disabled(isLoading)
            .padding(.horizontal, 4)

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
