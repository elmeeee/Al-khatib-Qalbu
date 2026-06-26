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
    @Bindable var presenter: HadithPresenter

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
                    if presenter.isLoading {
                        hadithLoadingBody
                    } else if presenter.loadErrorDescription != nil {
                        hadithErrorBody
                    } else if presenter.contentUnavailable {
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
        HStack(alignment: .center) {
            Text("Hadith")
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
                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.Token.gold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(presenter.verseReference)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                if presenter.isLoading == false, presenter.items.isEmpty == false {
                    Text("\(presenter.items.count) hadith\(presenter.items.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
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
                ForEach(presenter.items) { item in
                    hadithCard(item)
                }

                if presenter.hasMore {
                    Button {
                        Task { await presenter.loadMore() }
                    } label: {
                        Group {
                            if presenter.isLoadingMore {
                                ProgressView()
                                    .tint(Color.Token.deepEmerald)
                            } else {
                                Text("Load more")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.Token.deepEmerald)
                    .disabled(presenter.isLoadingMore)
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
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.Token.deepEmerald)
                Spacer(minLength: 8)
                if let reference = item.referenceLabel {
                    Text(reference)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if let chapter = item.chapterTitle, chapter.isEmpty == false {
                Text(chapter)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.Token.gold)
            }

            Text(item.body)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if item.gradeLines.isEmpty == false {
                HStack(spacing: 8) {
                    ForEach(item.gradeLines, id: \.self) { line in
                        let isSahih = line.lowercased().contains("sahih")
                        HStack(spacing: 4) {
                            Image(systemName: isSahih ? "checkmark.seal.fill" : "info.circle.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text(line)
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isSahih ? Color.green.opacity(0.12) : Color.Token.gold.opacity(0.12))
                        )
                        .foregroundColor(isSahih ? .green : Color.Token.gold)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.85))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.Token.softGrey.opacity(0.6), lineWidth: 1)
            )
    }

    @ViewBuilder
    private var hadithErrorBody: some View {
        if let desc = presenter.loadErrorDescription {
            ContentUnavailableView {
                Label("Couldn't load hadith", systemImage: "wifi.exclamationmark")
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
