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
        spacing: CGFloat = 2,
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
                rowHeightRange: rowHeightRange,
                maxItemsPerRow: maxItemsPerRow,
                metadata: metadata
            ).makeRows(items: items)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: spacing) {
                    ForEach(rows) { row in
                        HStack(alignment: .top, spacing: spacing) {
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

        case .advertisement(let advertisement):
            advertisementTile(advertisement)
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
    let rowHeightRange: ClosedRange<CGFloat>
    let maxItemsPerRow: Int
    let metadata: KlipyPageMeta?

    func makeRows(items: [KlipyContentItem]) -> [KlipyMasonryRowLayout] {
        guard containerWidth > 0, !items.isEmpty else {
            return []
        }

        let descriptors = items.map(KlipyMasonryLayoutDescriptor.init)
        var rows: [KlipyMasonryRowLayout] = []
        var pending: [KlipyMasonryLayoutDescriptor] = []

        for descriptor in descriptors {
            guard !pending.isEmpty else {
                pending = [descriptor]
                continue
            }

            let candidate = pending + [descriptor]

            if shouldStartNewRow(beforeAppending: descriptor, to: pending, candidate: candidate) {
                rows.append(makeRow(from: pending))
                pending = [descriptor]
                continue
            }

            pending = candidate

            if shouldFinalizeRow(pending) {
                rows.append(makeRow(from: pending))
                pending.removeAll(keepingCapacity: true)
            }
        }

        if !pending.isEmpty {
            rows.append(makeRow(from: pending))
        }

        return rows
    }

    private func shouldStartNewRow(
        beforeAppending descriptor: KlipyMasonryLayoutDescriptor,
        to pending: [KlipyMasonryLayoutDescriptor],
        candidate: [KlipyMasonryLayoutDescriptor]
    ) -> Bool {
        if candidate.count > rowItemLimit(for: candidate) {
            return true
        }

        let widthCheck = makeRow(from: candidate)
        if let minimumWidth = metadata?.itemMinWidth,
           widthCheck.items.contains(where: { $0.width < minimumWidth }) {
            return true
        }

        if descriptor.isAdvertisement, !pending.isEmpty {
            return idealRowHeight(for: pending) <= rowHeightRange.upperBound
        }

        return false
    }

    private func shouldFinalizeRow(_ descriptors: [KlipyMasonryLayoutDescriptor]) -> Bool {
        if descriptors.count >= rowItemLimit(for: descriptors) {
            return true
        }

        return idealRowHeight(for: descriptors) <= rowHeightRange.upperBound
    }

    private func rowItemLimit(for descriptors: [KlipyMasonryLayoutDescriptor]) -> Int {
        descriptors.contains(where: \.isAdvertisement) ? min(2, maxItemsPerRow) : maxItemsPerRow
    }

    private func idealRowHeight(for descriptors: [KlipyMasonryLayoutDescriptor]) -> CGFloat {
        let totalAspectRatio = descriptors.reduce(CGFloat.zero) { $0 + $1.aspectRatio }
        guard totalAspectRatio > 0 else {
            return rowHeightRange.lowerBound
        }

        let availableWidth = max(1, containerWidth - (CGFloat(descriptors.count - 1) * spacing))
        return availableWidth / totalAspectRatio
    }

    private func makeRow(from descriptors: [KlipyMasonryLayoutDescriptor]) -> KlipyMasonryRowLayout {
        let height = min(max(idealRowHeight(for: descriptors), rowHeightRange.lowerBound), rowHeightRange.upperBound)
        let availableWidth = max(1, containerWidth - (CGFloat(descriptors.count - 1) * spacing))
        let naturalWidths = descriptors.map { $0.aspectRatio * height }
        let remainder = max(0, availableWidth - naturalWidths.reduce(0, +))
        let adjustableIndices = descriptors.indices.filter { !descriptors[$0].isAdvertisement }
        let targets = adjustableIndices.isEmpty ? Array(descriptors.indices) : adjustableIndices
        let expansion = targets.isEmpty ? 0 : remainder / CGFloat(targets.count)

        let items = descriptors.enumerated().map { index, descriptor in
            let width = naturalWidths[index] + (targets.contains(index) ? expansion : 0)
            return KlipyMasonryItemLayout(
                item: descriptor.item,
                width: max(width, metadata?.itemMinWidth ?? 0),
                height: height
            )
        }

        return KlipyMasonryRowLayout(items: items, height: height)
    }
}

private struct KlipyMasonryLayoutDescriptor {
    let item: KlipyContentItem
    let aspectRatio: CGFloat
    let isAdvertisement: Bool

    init(item: KlipyContentItem) {
        self.item = item

        switch item {
        case .media(let media):
            aspectRatio = media.masonryAspectRatio
            isAdvertisement = false
        case .advertisement(let advertisement):
            aspectRatio = advertisement.masonryAspectRatio
            isAdvertisement = true
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

private extension KlipyAdvertisement {
    var masonryAspectRatio: CGFloat {
        let width = CGFloat(self.width ?? 320)
        let height = CGFloat(self.height ?? 100)
        return max(0.8, min(width / max(height, 1), 3.2))
    }
}
