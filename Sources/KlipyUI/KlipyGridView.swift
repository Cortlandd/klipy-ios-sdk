//
//  KlipyGridView.swift
//  KlipySDK
//
//  Created by Codex on 5/16/26.
//

import SwiftUI
import KlipyCore

struct KlipyGridView: View {
    @ObservedObject var viewModel: KlipyGridViewModel
    let onSelect: (KlipyMedia) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.lastError, viewModel.items.isEmpty {
                if error.isConnectivityError {
                    KlipyOfflineStateView {
                        viewModel.loadInitial()
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("Failed to load Klipy content.")
                            .font(.callout)
                            .foregroundStyle(palette.primaryText)
                        Text(error.description)
                            .font(.caption2)
                            .foregroundStyle(palette.secondaryText)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel.loadInitial()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                KlipyMasonryFeedView(
                    items: viewModel.items,
                    metadata: viewModel.layoutMetadata,
                    maxItemsPerRow: viewModel.configuration.maxItemsPerRow,
                    spacing: 0,
                    onLoadMore: { item in
                        viewModel.loadMoreIfNeeded(currentItem: item)
                    }
                ) { media in
                    Button {
                        onSelect(media)
                    } label: {
                        KlipyThumbnailView(media: media, isClipsMuted: .constant(true))
                    }
                    .buttonStyle(.plain)
                } advertisementTile: { advertisement in
                    KlipyAdvertisementView(advertisement: advertisement)
                } footer: {
                    if viewModel.isLoading && !viewModel.items.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.top, 2)
                .background(containerBackground)
            }
        }
        .onAppear {
            if viewModel.items.isEmpty {
                viewModel.loadInitial()
            }
        }
        .background(containerBackground)
    }

    private var palette: KlipyThemePalette {
        viewModel.configuration.theme.palette(for: colorScheme)
    }

    @ViewBuilder
    private var containerBackground: some View {
        if palette.chromeMaterial != nil {
            Rectangle()
                .fill(palette.chromeMaterial ?? .regularMaterial)
                .ignoresSafeArea()
        } else {
            palette.background
                .ignoresSafeArea()
        }
    }
}
