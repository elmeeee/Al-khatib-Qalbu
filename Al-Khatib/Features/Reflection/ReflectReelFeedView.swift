//
//  ReflectReelFeedView.swift
//  Al-Khatib
//

import SwiftUI

struct ReflectReelFeedView: View {
    @Bindable var viewModel: ReflectionViewModel
    @Environment(\.appContainer) private var container
    @State private var verseDetailViewModel = VerseDetailViewModel()

    var body: some View {
        ZStack {
            ReflectReelChrome.gradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ReflectFeedTabBarView(
                    selection: Binding(
                        get: { viewModel.selectedSegment },
                        set: { viewModel.onSegmentChanged(to: $0) }
                    )
                )

                GeometryReader { geo in
                    feedContent(pageHeight: geo.size.height, pageWidth: geo.size.width)
                }
            }
        }
        .sheet(item: verseSheetBinding) { item in
            ReflectVerseDetailSheetView(
                verseKey: item.id,
                response: verseDetailViewModel.verseSheetData,
                isLoading: verseDetailViewModel.isLoading
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
    }

    @ViewBuilder
    private func feedContent(pageHeight: CGFloat, pageWidth: CGFloat) -> some View {
        ZStack {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ReflectReelLoadingStack(pageHeight: pageHeight)
            } else if let error = viewModel.errorMessage, viewModel.posts.isEmpty {
                ReflectReelErrorStateView(
                    message: error,
                    segment: viewModel.selectedSegment,
                    retry: { viewModel.onSegmentChanged(to: viewModel.selectedSegment) }
                )
            } else if viewModel.posts.isEmpty {
                ReflectReelEmptyStateView(segment: viewModel.selectedSegment)
            } else {
                reelPager(pageHeight: pageHeight, pageWidth: pageWidth)
            }

            if viewModel.isLoading && viewModel.posts.isEmpty == false {
                VStack {
                    ProgressView()
                        .tint(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding(.top, 8)
            }

            if viewModel.isLoadingMore {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .padding(.bottom, 24)
                }
            }
        }
    }

    private func reelPager(pageHeight: CGFloat, pageWidth: CGFloat) -> some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.posts) { post in
                    ReflectReelPageView(
                        post: post,
                        pageHeight: pageHeight,
                        isTogglingLike: viewModel.isTogglingLike(postId: post.id),
                        onToggleLike: {
                            Task { await viewModel.toggleLike(for: post) }
                        },
                        onTapVerse: { key in
                            Task {
                                await verseDetailViewModel.open(
                                    verseKey: key,
                                    content: container?.content
                                )
                            }
                        }
                    )
                    .frame(width: pageWidth, height: pageHeight)
                    .id(post.id)
                    .onAppear {
                        viewModel.loadMoreIfNeeded(currentPost: post)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .scrollIndicators(.hidden)
        .clipped()
        .refreshable {
            await viewModel.loadPosts(refresh: true, force: true)
        }
    }

    private var verseSheetBinding: Binding<VerseSheetItem?> {
        Binding(
            get: {
                guard let key = verseDetailViewModel.selectedVerseKey else { return nil }
                return VerseSheetItem(verseKey: key)
            },
            set: { newValue in
                if newValue == nil {
                    verseDetailViewModel.reset()
                }
            }
        )
    }
}
