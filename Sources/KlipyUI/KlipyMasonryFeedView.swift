//
//  KlipyMasonryFeedView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import SwiftUI
import KlipyCore

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
        GeometryReader { geometry in
            let rows = KlipyMasonryLayoutCalculator(
                containerWidth: geometry.size.width,
                spacing: spacing,
                tileInset: tileInset,
                rowHeightRange: rowHeightRange,
                maxItemsPerRow: maxItemsPerRow,
                metadata: metadata
            ).makeRows(items: items)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { row in
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(row.items) { layout in
                                tileView(for: layout)
                                    .frame(width: layout.width, height: layout.height)
                                    .onAppear {
                                        onLoadMore(layout.item)
                                    }
                            }
                        }
                        .frame(height: row.height)
                    }

                    footer
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func tileView(for layout: KlipyMasonryItemLayout) -> some View {
        switch layout.item {
        case .media(let media):
            mediaTile(media)
                .padding(tileInset)

        case .advertisement(let advertisement):
            advertisementTile(advertisement)
                .padding(tileInset)
        }
    }
}

struct KlipyMasonryItemLayout: Identifiable, Equatable {
    let item: KlipyContentItem
    let width: CGFloat
    let height: CGFloat

    var id: String { item.id }
}

struct KlipyMasonryRowLayout: Identifiable, Equatable {
    let items: [KlipyMasonryItemLayout]
    let height: CGFloat

    var id: String {
        items.map(\.id).joined(separator: "|")
    }
}

struct KlipyMasonryLayoutCalculator {
    let containerWidth: CGFloat
    let spacing: CGFloat
    let tileInset: CGFloat
    let rowHeightRange: ClosedRange<CGFloat>
    let maxItemsPerRow: Int
    let metadata: KlipyPageMeta?

    func makeRows(items: [KlipyContentItem]) -> [KlipyMasonryRowLayout] {
        guard containerWidth > 0, !items.isEmpty else {
            return []
        }

        var rows: [KlipyMasonryRowLayout] = []
        let candidates = items.map(KlipyMasonryLayoutCandidate.init)
        var nextIndex = 0

        while nextIndex < candidates.count {
            let endIndex = min(nextIndex + maxItemsPerRow, candidates.count)
            let possibleItems = Array(candidates[nextIndex..<endIndex])
            let (rowCandidates, rowHeight) = calculateOptimalRow(
                possibleItems,
                itemMinWidth: metadata?.itemMinWidth ?? 0,
                adMaxResizePercent: metadata?.adMaxResizePercent ?? 0
            )

            rows.append(
                KlipyMasonryRowLayout(
                    items: rowCandidates.map {
                        KlipyMasonryItemLayout(
                            item: $0.item,
                            width: $0.width,
                            height: $0.height
                        )
                    },
                    height: rowHeight
                )
            )

            nextIndex += max(1, rowCandidates.count)
        }

        return rows
    }

    private func calculateOptimalRow(
        _ candidateItems: [KlipyMasonryLayoutCandidate],
        itemMinWidth: CGFloat,
        adMaxResizePercent: CGFloat
    ) -> ([KlipyMasonryLayoutCandidate], CGFloat) {
        var minimumChange = CGFloat.greatestFiniteMagnitude
        var optimizedRow: [KlipyMasonryLayoutCandidate] = []
        var optimalRowHeight: CGFloat = 0

        var currentMinHeight = rowHeightRange.lowerBound
        var currentMaxHeight = rowHeightRange.upperBound

        let adIndex = candidateItems.firstIndex(where: \.isAdvertisement)
        if let adIndex, adIndex > 1 {
            return calculateOptimalRow(Array(candidateItems.prefix(2)), itemMinWidth: itemMinWidth, adMaxResizePercent: adMaxResizePercent)
        } else if let adIndex {
            currentMinHeight = candidateItems[adIndex].height
            currentMaxHeight = candidateItems[adIndex].height
        }

        if currentMinHeight > currentMaxHeight {
            currentMaxHeight = currentMinHeight
        }

        let itemPadding = tileInset * 2

        for height in Int(currentMinHeight)...Int(currentMaxHeight) {
            var itemsInRow: [KlipyMasonryLayoutCandidate] = []

            for item in candidateItems {
                var newItem = item
                if item.isAdvertisement {
                    newItem.newWidth = max(1, item.width - itemPadding)
                } else {
                    newItem.newWidth = max(
                        1,
                        round((item.originalWidth * CGFloat(height)) / max(item.originalHeight, 1)) - itemPadding
                    )
                }

                itemsInRow.append(newItem)

                let totalWidth = itemsInRow.reduce(CGFloat.zero) { $0 + $1.newWidth } + (CGFloat(itemsInRow.count - 1) * spacing)
                let change = containerWidth - totalWidth

                if abs(change) < abs(minimumChange) || (optimizedRow.count == 1 && itemsInRow.count != 1) {
                    if itemsInRow.count != 1 || optimizedRow.isEmpty {
                        minimumChange = change
                        optimizedRow = itemsInRow
                        optimalRowHeight = CGFloat(height)
                    }
                }
            }
        }

        let nonAdItems = optimizedRow.filter { !$0.isAdvertisement }
        let adjustmentPerItem = nonAdItems.isEmpty ? 0 : minimumChange / CGFloat(nonAdItems.count)

        for index in optimizedRow.indices {
            if optimizedRow[index].isAdvertisement {
                optimizedRow[index].width = optimizedRow[index].newWidth
            } else {
                optimizedRow[index].width = optimizedRow[index].newWidth + adjustmentPerItem
            }
            optimizedRow[index].height = optimalRowHeight
            optimizedRow[index].width += itemPadding
        }

        if let adIndex, nonAdItems.count != optimizedRow.count {
            let itemsBelowMinWidth = nonAdItems.filter { $0.width < itemMinWidth }

            if !itemsBelowMinWidth.isEmpty {
                for index in optimizedRow.indices where !optimizedRow[index].isAdvertisement && optimizedRow[index].width < itemMinWidth {
                    optimizedRow[index].width = itemMinWidth
                }

                let newRowWidth = optimizedRow.reduce(CGFloat.zero) { $0 + $1.width } + (CGFloat(optimizedRow.count - 1) * spacing)

                if newRowWidth > containerWidth {
                    var adItem = optimizedRow[adIndex]
                    let minAdWidth = adItem.width * ((100 - adMaxResizePercent) / 100)
                    var resizedAdWidth = adItem.width - (newRowWidth - containerWidth)

                    if resizedAdWidth < minAdWidth {
                        let adWidthDifference = minAdWidth - resizedAdWidth
                        let adjustableCount = max(1, itemsBelowMinWidth.count)

                        for index in optimizedRow.indices where !optimizedRow[index].isAdvertisement && optimizedRow[index].width == itemMinWidth {
                            optimizedRow[index].width -= adWidthDifference / CGFloat(adjustableCount)
                        }

                        resizedAdWidth = minAdWidth
                    }

                    let scaleFactor = resizedAdWidth / max(adItem.width, 1)
                    adItem.height *= scaleFactor
                    adItem.width = resizedAdWidth
                    adItem.newWidth = resizedAdWidth
                    optimizedRow[adIndex] = adItem

                    for index in optimizedRow.indices where !optimizedRow[index].isAdvertisement {
                        optimizedRow[index].height = adItem.height
                    }

                    optimalRowHeight = adItem.height
                }
            }
        }

        return (optimizedRow, optimalRowHeight)
    }
}

private struct KlipyMasonryLayoutCandidate {
    let item: KlipyContentItem
    let isAdvertisement: Bool
    let originalWidth: CGFloat
    let originalHeight: CGFloat
    var width: CGFloat
    var height: CGFloat
    var newWidth: CGFloat = 0

    init(item: KlipyContentItem) {
        self.item = item

        switch item {
        case .media(let media):
            isAdvertisement = false
            let dimensions = media.preferredLayoutDimensions ?? CGSize(
                width: max(media.displayAspectRatio, 0.55) * 100,
                height: 100
            )
            originalWidth = max(dimensions.width, 1)
            originalHeight = max(dimensions.height, 1)
            width = originalWidth
            height = originalHeight
        case .advertisement(let advertisement):
            isAdvertisement = true
            let widthValue = max(CGFloat(advertisement.width ?? 320), 1)
            let heightValue = max(CGFloat(advertisement.height ?? 100), 1)
            originalWidth = widthValue
            originalHeight = heightValue
            width = widthValue
            height = heightValue
        }
    }
}

private extension KlipyMedia {
    var masonryAspectRatio: CGFloat {
        if let dimensions = preferredLayoutDimensions {
            let ratio = dimensions.width / max(dimensions.height, 1)
            return max(0.55, min(ratio, 2.8))
        }

        return max(0.55, min(displayAspectRatio, 2.8))
    }

    var preferredLayoutDimensions: CGSize? {
        let assets: [KlipyMediaFileAsset?] = [
            file?.sm?.webp,
            file?.sm?.gif,
            file?.sm?.jpg,
            file?.xs?.webp,
            file?.xs?.gif,
            file?.xs?.jpg,
            file?.md?.webp,
            file?.md?.gif,
            file?.md?.jpg,
            file?.hd?.webp,
            file?.hd?.gif,
            file?.hd?.jpg
        ]

        for asset in assets {
            if let width = asset?.width, let height = asset?.height, height > 0 {
                return CGSize(width: width, height: height)
            }
        }

        let metaEntries = [
            fileMeta?.webp,
            fileMeta?.gif,
            fileMeta?.mp4
        ]

        for entry in metaEntries {
            if let width = entry?.width, let height = entry?.height, height > 0 {
                return CGSize(width: width, height: height)
            }
        }

        return nil
    }
}
