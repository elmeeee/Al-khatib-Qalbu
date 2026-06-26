//
//  TafsirReaderSheet.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct TafsirReaderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var presenter: TafsirPresenter

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
                Divider().opacity(0.4)

                Group {
                    let hasHTML = !presenter.htmlFragment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    if presenter.isLoading || (!hasHTML && presenter.loadErrorDescription == nil && !presenter.commentaryUnavailable) {
                        tafsirLoadingBody
                    } else if presenter.loadErrorDescription != nil {
                        tafsirErrorBody
                    } else if presenter.commentaryUnavailable {
                        tafsirEmptyBody
                    } else {
                        HTMLContentWebView(htmlFragment: presenter.htmlFragment, style: .tafsirReader)
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
    }

    private var sheetTopBar: some View {
        HStack(alignment: .center) {
            Text("Tafsir")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.Token.deepEmerald)
            
            Spacer()
            
            HStack(spacing: 12) {
                // Custom Language Selector Pills
                HStack(spacing: 2) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            if presenter.selectedLanguage != lang {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                    presenter.selectedLanguage = lang
                                }
                                Task { await presenter.reload() }
                            }
                        } label: {
                            Text(lang.rawValue.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(presenter.selectedLanguage == lang ? .white : Color.Token.deepEmerald.opacity(0.8))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(presenter.selectedLanguage == lang ? Color.Token.deepEmerald : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Capsule().fill(Color.black.opacity(0.04)))
                
                Button("Done") { dismiss() }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.Token.deepEmerald)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var verseContextHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.Token.gold.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "text.alignleft")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.Token.gold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(presenter.verseReference)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Group {
                    if presenter.isLoading {
                        SkeletonBar(width: 140, height: 10, cornerRadius: 5)
                    } else if let source = presenter.commentarySource {
                        Text(source)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.Token.deepEmerald, Color.Token.tealDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.Token.deepEmerald.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
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
        if let desc = presenter.loadErrorDescription {
            ContentUnavailableView {
                Label("Couldn't load tafsir", systemImage: "wifi.exclamationmark")
            } description: {
                Text(desc)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            } actions: {
                Button("Try again") {
                    Task { await presenter.reload() }
                }
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
