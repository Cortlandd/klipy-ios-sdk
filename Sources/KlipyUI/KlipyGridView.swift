//
//  KlipyGridView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/16/26.
//

import SwiftUI
import KlipyCore
import ComposableArchitecture

struct KlipyGridView: View {
    let store: StoreOf<KlipyGridFeature>
    let onSelect: (KlipyMedia) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WithPerceptionTracking {
            Group {
                if store.isLoading && store.items.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = store.errorMessage, store.items.isEmpty {
                    if store.isOffline {
                        KlipyOfflineStateView {
                            store.send(.retryTapped)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text("Failed to load Klipy content.")
                                .font(.callout)
                                .foregroundStyle(palette.primaryText)
                            Text(errorMessage)
                                .font(.caption2)
                                .foregroundStyle(palette.secondaryText)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                store.send(.retryTapped)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    KlipyMasonryFeedView(
                        items: store.items,
                        metadata: store.layoutMetadata,
                        maxItemsPerRow: store.configuration.maxItemsPerRow,
                        spacing: 0,
                        onLoadMore: { item in
                            store.send(.loadMoreIfNeeded(item.id))
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
                        if store.isLoading && !store.items.isEmpty {
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
                store.send(.onAppear)
            }
            .background(containerBackground)
        }
    }

    private var palette: KlipyThemePalette {
        store.configuration.theme.palette(for: colorScheme)
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
