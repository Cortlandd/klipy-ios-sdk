//
//  KlipyMasonryFeedView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import SwiftUI
import KlipyCore

public struct KlipyMasonryFeedView<MediaTile: View, AdvertisementTile: View, Footer: View>: View {
    private let items: [KlipyContentItem]
    private let metadata: KlipyPageMeta?
    private let maxItemsPerRow: Int
    private let spacing: CGFloat
    private let rowHeightRange: ClosedRange<CGFloat>
    private let onLoadMore: (KlipyContentItem) -> Void
    private let mediaTile: (KlipyMedia) -> MediaTile
    private let advertisementTile: (KlipyAdvertisement) -> AdvertisementTile
    private let footer: Footer

    public init(
        items: [KlipyContentItem],
        metadata: KlipyPageMeta?,
        maxItemsPerRow: Int,
        spacing: CGFloat = 1,
        rowHeightRange: ClosedRange<CGFloat> = 50...180,
        onLoadMore: @escaping (KlipyContentItem) -> Void,
        @ViewBuilder mediaTile: @escaping (KlipyMedia) -> MediaTile,
        @ViewBuilder advertisementTile: @escaping (KlipyAdvertisement) -> AdvertisementTile,
        @ViewBuilder footer: () -> Footer
    ) {
        self.items = items
        self.metadata = metadata
        self.maxItemsPerRow = max(2, maxItemsPerRow)
        self.spacing = max(0, spacing)
        self.rowHeightRange = rowHeightRange
        self.onLoadMore = onLoadMore
        self.mediaTile = mediaTile
        self.advertisementTile = advertisementTile
        self.footer = footer()
    }

    public var body: some View {
        GeometryReader { geometry in
            let rows = makeRows(containerWidth: geometry.size.width)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        KlipyMasonryRowView(
                            row: row,
                            isLastRow: index == rows.count - 1,
                            onLoadMore: onLoadMore,
                            mediaTile: mediaTile,
                            advertisementTile: advertisementTile
                        )
                        .padding(.bottom, spacing)
                    }

                    footer
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func makeRows(containerWidth: CGFloat) -> [KlipyMasonryRowLayout] {
        guard containerWidth > 0 else {
            return []
        }

        return KlipyMasonryLayoutCalculator(
            containerWidth: containerWidth,
            horizontalSpacing: spacing,
            minRowHeight: rowHeightRange.lowerBound,
            maxRowHeight: rowHeightRange.upperBound,
            maxItemsPerRow: maxItemsPerRow
        )
        .createRows(from: items, metadata: metadata)
    }
}

private struct KlipyMasonryRowView<MediaTile: View, AdvertisementTile: View>: View {
    let row: KlipyMasonryRowLayout
    let isLastRow: Bool
    let onLoadMore: (KlipyContentItem) -> Void
    let mediaTile: (KlipyMedia) -> MediaTile
    let advertisementTile: (KlipyAdvertisement) -> AdvertisementTile

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(row.items) { item in
                tile(for: item)
                    .frame(width: item.width, height: item.height)
                    .offset(x: item.xPosition, y: 0)
                    .onAppear {
                        guard isLastRow else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onLoadMore(item.contentItem)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, minHeight: row.height, maxHeight: row.height, alignment: .leading)
    }

    @ViewBuilder
    private func tile(for item: KlipyMasonryLayoutItem) -> some View {
        switch item.contentItem {
        case .media(let media):
            mediaTile(media)
                .frame(width: item.width, height: item.height)
                .clipped()

        case .advertisement(let advertisement):
            advertisementTile(advertisement)
                .frame(width: item.width, height: item.height)
                .clipped()
        }
    }
}
