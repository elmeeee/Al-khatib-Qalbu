//
//  TafsirReaderSheet.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct TafsirReaderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let verseReference: String
    let commentarySource: String?
    let isLoading: Bool
    let loadErrorDescription: String?
    let commentaryUnavailable: Bool
    let htmlFragment: String
    let reload: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.Token.offWhite, Color.Token.sageMist],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetTopBar
                verseContextHeader
                Divider().opacity(0.55)

                Group {
                    let hasHTML = !htmlFragment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    if isLoading || (!hasHTML && loadErrorDescription == nil && !commentaryUnavailable) {
                        tafsirLoadingBody
                    } else if loadErrorDescription != nil {
                        tafsirErrorBody
                    } else if commentaryUnavailable {
                        tafsirEmptyBody
                    } else {
                        HTMLContentWebView(htmlFragment: htmlFragment, style: .tafsirReader)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(22)
        .animation(nil, value: isLoading)
        .animation(nil, value: htmlFragment)
    }

    private var sheetTopBar: some View {
        HStack {
            Text("Tafsir")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.Token.deepEmerald)
            Spacer()
            Button("Done") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.Token.deepEmerald)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var verseContextHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "text.alignleft")
                .font(.title2)
                .foregroundStyle(Color.Token.deepEmerald.opacity(0.88))
                .frame(width: 36, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text(verseReference)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.Token.deepEmerald)
                    .multilineTextAlignment(.leading)

                Group {
                    if isLoading {
                        SkeletonBar(width: 180, height: 11, cornerRadius: 5)
                    } else if let source = commentarySource {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Image(systemName: "book.pages.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 14, alignment: .leading)
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
                .stroke(Color.Token.softGrey.opacity(0.65), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .animation(nil, value: isLoading)
        .animation(nil, value: commentarySource ?? "")
    }

    private var tafsirLoadingBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SkeletonBar(width: nil, height: 14, cornerRadius: 6)
                SkeletonBar(width: nil, height: 14, cornerRadius: 6)
                SkeletonBar(width: 280, height: 14, cornerRadius: 6)
                SkeletonBar(width: nil, height: 14, cornerRadius: 6)
                SkeletonBar(width: nil, height: 14, cornerRadius: 6)
                SkeletonBar(width: 220, height: 14, cornerRadius: 6)
                ForEach(0..<6, id: \.self) { i in
                    SkeletonBar(
                        width: i % 3 == 0 ? nil : CGFloat(300 - i * 12),
                        height: 12,
                        cornerRadius: 5
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
    }

    @ViewBuilder
    private var tafsirErrorBody: some View {
        if let desc = loadErrorDescription {
            ContentUnavailableView {
                Label("Couldn't load tafsir", systemImage: "wifi.exclamationmark")
            } description: {
                Text(desc)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            } actions: {
                Button("Try again", action: reload)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.Token.deepEmerald)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var tafsirEmptyBody: some View {
        ContentUnavailableView {
            Label("No commentary here", systemImage: "text.book.closed")
        } description: {
            Text("This verse doesn't include tafsir text for this source yet.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
