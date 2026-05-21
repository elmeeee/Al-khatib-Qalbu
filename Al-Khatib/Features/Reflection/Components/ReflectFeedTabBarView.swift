//
//  ReflectFeedTabBarView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct ReflectFeedTabBarView: View {
    @Binding var selection: ReflectPostsSegment
    @Namespace private var tabNamespace

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ReflectPostsSegment.allCases) { segment in
                let isSelected = selection == segment
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selection = segment
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: segment == .feed ? "sparkles" : "person.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(segment.title)
                            .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                    }
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.45))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(.white.opacity(0.15))
                                .matchedGeometryEffect(id: "reflectTab", in: tabNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    AlKhatibAccessibility.Reflect.segmentTab(segment.title, isSelected: isSelected)
                )
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial.opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }
}
