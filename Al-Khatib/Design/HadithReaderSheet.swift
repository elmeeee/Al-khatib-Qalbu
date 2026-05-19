//
//  HadithReaderSheet.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct HadithReaderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let verseReference: String
    let items: [HadithDisplayItem]
    let isLoading: Bool
    let isLoadingMore: Bool
    let hasMore: Bool
    let loadErrorDescription: String?
    let contentUnavailable: Bool
    let reload: () -> Void
    let loadMore: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.Theme.offWhite, Color(hex: "#F1F5F2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetTopBar
                verseContextHeader
                Divider().opacity(0.55)

                Group {
                    if isLoading {
                        hadithLoadingBody
                    } else if loadErrorDescription != nil {
                        hadithErrorBody
                    } else if contentUnavailable {
                        hadithEmptyBody
                    } else {
                        hadithListBody
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(22)
    }

    private var sheetTopBar: some View {
        HStack {
            Text("Hadith")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.Theme.deepEmerald)
            Spacer()
            Button("Done") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.Theme.deepEmerald)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var verseContextHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "text.book.closed.fill")
                .font(.title2)
                .foregroundStyle(Color.Theme.deepEmerald.opacity(0.88))
                .frame(width: 36, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text(verseReference)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.Theme.deepEmerald)
                    .multilineTextAlignment(.leading)

                if isLoading == false, items.isEmpty == false {
                    Text("\(items.count) hadith\(items.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.Theme.softGrey.opacity(0.65), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var hadithLoadingBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 10) {
                        SkeletonBar(width: 160, height: 12, cornerRadius: 5)
                        SkeletonBar(width: nil, height: 12, cornerRadius: 5)
                        SkeletonBar(width: nil, height: 12, cornerRadius: 5)
                        SkeletonBar(width: 240, height: 12, cornerRadius: 5)
                    }
                    .padding(14)
                    .background(cardBackground)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var hadithListBody: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    hadithCard(item)
                }

                if hasMore {
                    Button {
                        loadMore()
                    } label: {
                        Group {
                            if isLoadingMore {
                                ProgressView()
                                    .tint(Color.Theme.deepEmerald)
                            } else {
                                Text("Load more")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.Theme.deepEmerald)
                    .disabled(isLoadingMore)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func hadithCard(_ item: HadithDisplayItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.sourceName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.Theme.deepEmerald)
                Spacer(minLength: 8)
                if let reference = item.referenceLabel {
                    Text(reference)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            if let chapter = item.chapterTitle, chapter.isEmpty == false {
                Text(chapter)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.Theme.gold)
            }

            Text(item.body)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if item.gradeLines.isEmpty == false {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(item.gradeLines, id: \.self) { line in
                        Label(line, systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(Color.Theme.deepEmerald.opacity(0.85))
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.82))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.Theme.softGrey.opacity(0.65), lineWidth: 1)
            )
    }

    @ViewBuilder
    private var hadithErrorBody: some View {
        if let desc = loadErrorDescription {
            ContentUnavailableView {
                Label("Couldn't load hadith", systemImage: "wifi.exclamationmark")
            } description: {
                Text(desc)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            } actions: {
                Button("Try again", action: reload)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.Theme.deepEmerald)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var hadithEmptyBody: some View {
        ContentUnavailableView {
            Label("No hadith here", systemImage: "text.book.closed")
        } description: {
            Text("No hadith references are linked to this ayah yet.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
