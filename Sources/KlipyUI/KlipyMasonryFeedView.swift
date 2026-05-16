//
//  KlipyMasonryFeedView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import SwiftUI
import KlipyCore
import SwiftUIMasonry

public struct KlipyMasonryFeedView<MediaTile: View, AdvertisementTile: View, Footer: View>: View {
    private let tileInset: CGFloat
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
        spacing: CGFloat = 0,
        tileInset: CGFloat = 1,
        rowHeightRange: ClosedRange<CGFloat> = 92...190,
        onLoadMore: @escaping (KlipyContentItem) -> Void,
        @ViewBuilder mediaTile: @escaping (KlipyMedia) -> MediaTile,
        @ViewBuilder advertisementTile: @escaping (KlipyAdvertisement) -> AdvertisementTile,
        @ViewBuilder footer: () -> Footer
    ) {
        self.items = items
        self.metadata = metadata
        self.maxItemsPerRow = max(2, maxItemsPerRow)
        self.spacing = spacing
        self.tileInset = tileInset
        self.rowHeightRange = rowHeightRange
        self.onLoadMore = onLoadMore
        self.mediaTile = mediaTile
        self.advertisementTile = advertisementTile
        self.footer = footer()
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VMasonry(
                    columns: .fixed(maxItemsPerRow),
                    horizontalSpacing: layoutSpacing,
                    verticalSpacing: layoutSpacing,
                    data: items
                ) { item in
                    tileView(for: item)
                        .onAppear {
                            onLoadMore(item)
                        }
                } columnSpan: { item in
                    .fixed(KlipyMasonryFeedLayoutPolicy.columnSpan(for: item, maxItemsPerRow: maxItemsPerRow))
                }
                .masonryPlacementMode(.order)

                footer
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var layoutSpacing: CGFloat {
        KlipyMasonryFeedLayoutPolicy.effectiveSpacing(
            spacing: spacing,
            tileInset: tileInset
        )
    }

    @ViewBuilder
    private func tileView(for item: KlipyContentItem) -> some View {
        switch item {
        case .media(let media):
            mediaTile(media)
                .aspectRatio(media.displayAspectRatio, contentMode: .fit)
                .clipped()

        case .advertisement(let advertisement):
            advertisementTile(advertisement)
                .aspectRatio(advertisement.displayAspectRatio, contentMode: .fit)
                .frame(minHeight: rowHeightRange.lowerBound)
                .clipped()
        }
    }
}

enum KlipyMasonryFeedLayoutPolicy {
    static func effectiveSpacing(spacing: CGFloat, tileInset: CGFloat) -> CGFloat {
        if spacing > 0 {
            return spacing
        }
        return max(tileInset * 2, 0)
    }

    static func columnSpan(for item: KlipyContentItem, maxItemsPerRow: Int) -> Int {
        guard item.advertisement != nil else {
            return 1
        }

        if maxItemsPerRow >= 3 {
            return 2
        }

        return maxItemsPerRow
    }
}
