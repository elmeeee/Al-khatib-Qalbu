//
//  ReflectReelSkeletonPageView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectReelSkeletonPageView: View {
    let pageHeight: CGFloat

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack {
            ReflectReelChrome.gradient

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        Circle().fill(.white.opacity(0.08)).frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 6) {
                            skeletonBar(width: 130, height: 14)
                            skeletonBar(width: 80, height: 11)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    Rectangle()
                        .fill(.white.opacity(0.04))
                        .frame(height: 0.5)
                        .padding(.horizontal, 18)
                        .padding(.top, 14)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(0..<4, id: \.self) { i in
                            skeletonBar(width: i == 3 ? 200 : nil, height: 15)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 18)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.trailing, 48)

                Spacer()
            }

            VStack {
                Spacer()
                VStack(spacing: 22) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(.white.opacity(0.08)).frame(width: 48, height: 48)
                    }
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 108)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(height: pageHeight)
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }

    private func skeletonBar(width: CGFloat? = nil, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.white.opacity(0.06))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.05), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
            )
            .clipped()
    }
}
