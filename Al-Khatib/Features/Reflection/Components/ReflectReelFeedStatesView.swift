//
//  ReflectReelFeedStatesView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectReelLoadingStack: View {
    let pageHeight: CGFloat

    var body: some View {
        TabView {
            ForEach(0..<3, id: \.self) { _ in
                ReflectReelSkeletonPageView(pageHeight: pageHeight)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .scrollIndicators(.hidden)
    }
}

struct ReflectReelErrorStateView: View {
    let message: String
    let segment: ReflectPostsSegment
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 88, height: 88)
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text(segment == .myPosts ? "Couldn\u{2019}t load your reflections" : "Couldn\u{2019}t load all reflections")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: retry) {
                Text("Try again")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.Theme.deepEmerald)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .alKhatibAccessibility(label: AlKhatibAccessibility.Reflect.tryAgain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ReflectReelEmptyStateView: View {
    let segment: ReflectPostsSegment

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 96, height: 96)
                Circle()
                    .fill(.white.opacity(0.04))
                    .frame(width: 72, height: 72)
                Image(systemName: segment == .myPosts ? "person.crop.rectangle.stack" : "sparkles")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Text(segment == .myPosts ? "No reflections yet" : "Nothing here yet")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(
                segment == .myPosts
                    ? "Publish a reflection from Today to see it here."
                    : "Be the first \u{2014} share what this ayah means to you."
            )
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.65))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

            if segment == .myPosts {
                Text("Start Reflecting")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.Theme.deepEmerald)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(.white)
                    .clipShape(Capsule())
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
