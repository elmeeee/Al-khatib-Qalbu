//
//  SkeletonView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

enum SkeletonTone {
    case light
}

struct SkeletonBar: View {
    var width: CGFloat?
    var height: CGFloat = 12
    var cornerRadius: CGFloat = 8
    var tone: SkeletonTone = .light

    init(
        width: CGFloat? = nil,
        height: CGFloat = 12,
        cornerRadius: CGFloat = 8,
        tone: SkeletonTone = .light
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.tone = tone
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(baseFill)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.clear)
                    .skeletonShimmer(tone: tone)
            }
    }

    private var baseFill: Color {
        Color(.systemGray5)
    }
}

struct SkeletonCapsuleBar: View {
    var tone: SkeletonTone = .light
    var body: some View {
        SkeletonBar(cornerRadius: 999, tone: tone)
    }
}

struct SkeletonCircleDot: View {
    var size: CGFloat = 44
    var tone: SkeletonTone = .light

    var body: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: size, height: size)
            .skeletonShimmer(tone: tone)
    }
}

extension View {
    func skeletonShimmer(tone _: SkeletonTone = .light) -> some View {
        self
    }
}

struct LoadingSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SkeletonBar(width: 180, height: 28, cornerRadius: 8)
                .padding(.bottom, 4)

            ForEach(0..<4, id: \.self) { i in
                VStack(alignment: .leading, spacing: 10) {
                    SkeletonBar(width: 120, height: 14)
                    SkeletonBar(width: nil, height: 12)
                    SkeletonBar(width: i % 2 == 0 ? nil : 200, height: 12)
                }
                .padding(16)
                .flatCard()
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.Theme.offWhite)
    }
}
