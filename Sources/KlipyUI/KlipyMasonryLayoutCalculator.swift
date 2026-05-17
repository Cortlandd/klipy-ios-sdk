//
//  KlipyMasonryLayoutCalculator.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/16/26.
//

import Foundation
import CoreGraphics
import KlipyCore

struct KlipyMasonryLayoutItem: Identifiable, Equatable {
    let id: String
    let contentItem: KlipyContentItem
    let originalWidth: CGFloat
    let originalHeight: CGFloat
    let type: String

    var width: CGFloat
    var height: CGFloat
    var xPosition: CGFloat = 0
    var yPosition: CGFloat = 0
    var newWidth: CGFloat = 0

    init(contentItem: KlipyContentItem, width: CGFloat, height: CGFloat, type: String) {
        self.id = contentItem.id
        self.contentItem = contentItem
        self.originalWidth = width
        self.originalHeight = height
        self.width = width
        self.height = height
        self.type = type
    }
}

struct KlipyMasonryRowLayout: Equatable {
    var items: [KlipyMasonryLayoutItem]
    var height: CGFloat
}

final class KlipyMasonryLayoutCalculator {
    private let containerWidth: CGFloat
    private let horizontalSpacing: CGFloat
    private let minRowHeight: CGFloat
    private let maxRowHeight: CGFloat
    private let maxItemsPerRow: Int

    init(
        containerWidth: CGFloat,
        horizontalSpacing: CGFloat = 1,
        minRowHeight: CGFloat = 50,
        maxRowHeight: CGFloat = 180,
        maxItemsPerRow: Int = 4
    ) {
        self.containerWidth = containerWidth
        self.horizontalSpacing = horizontalSpacing
        self.minRowHeight = minRowHeight
        self.maxRowHeight = maxRowHeight
        self.maxItemsPerRow = maxItemsPerRow
    }

    func createRows(from items: [KlipyContentItem], metadata: KlipyPageMeta?) -> [KlipyMasonryRowLayout] {
        var rows: [KlipyMasonryRowLayout] = []
        var nextItemIndex = 0

        let itemMinWidth = Int((metadata?.itemMinWidth ?? 50).rounded())
        let adMaxResizePercent = Int((metadata?.adMaxResizePercent ?? 20).rounded())

        while nextItemIndex < items.count {
            let candidateItems = Array(items[nextItemIndex..<min(nextItemIndex + maxItemsPerRow, items.count)])
            let candidateLayoutItems = candidateItems.map(makeLayoutItem)

            let (rowItems, rowHeight) = calculateOptimalRow(
                candidateLayoutItems,
                itemMinWidth,
                adMaxResizePercent
            )

            rows.append(KlipyMasonryRowLayout(items: rowItems, height: rowHeight))
            nextItemIndex += rowItems.count
        }

        var currentY: CGFloat = 0
        for rowIndex in rows.indices {
            var currentX: CGFloat = 0
            for itemIndex in rows[rowIndex].items.indices {
                rows[rowIndex].items[itemIndex].xPosition = currentX
                rows[rowIndex].items[itemIndex].yPosition = currentY
                currentX += rows[rowIndex].items[itemIndex].width + horizontalSpacing
            }
            currentY += rows[rowIndex].height + horizontalSpacing
        }

        return rows
    }

    private func makeLayoutItem(from item: KlipyContentItem) -> KlipyMasonryLayoutItem {
        switch item {
        case .media(let media):
            let size = media.layoutDimensions
            return KlipyMasonryLayoutItem(
                contentItem: item,
                width: size.width,
                height: size.height,
                type: media.type.rawValue
            )

        case .advertisement(let advertisement):
            let size = advertisement.layoutDimensions
            return KlipyMasonryLayoutItem(
                contentItem: item,
                width: size.width,
                height: size.height,
                type: advertisement.type
            )
        }
    }

    private func calculateOptimalRow(
        _ candidateItems: [KlipyMasonryLayoutItem],
        _ itemMinWidth: Int,
        _ adMaxResizePercent: Int
    ) -> ([KlipyMasonryLayoutItem], CGFloat) {
        var minimumChange = CGFloat.greatestFiniteMagnitude
        var optimizedRow: [KlipyMasonryLayoutItem] = []
        var optimalRowHeight: CGFloat = 0

        var currentMinHeight = minRowHeight
        var currentMaxHeight = maxRowHeight

        let adIndex = candidateItems.firstIndex { $0.type == "ad" }
        if let adIndex, adIndex > 1 {
            let items = Array(candidateItems.prefix(2))
            return calculateOptimalRow(items, itemMinWidth, adMaxResizePercent)
        } else if let adIndex {
            currentMinHeight = candidateItems[adIndex].height
            currentMaxHeight = candidateItems[adIndex].height
        }

        for height in Int(currentMinHeight)...Int(currentMaxHeight) {
            var itemsInRow: [KlipyMasonryLayoutItem] = []

            for item in candidateItems {
                var newItem = item
                if item.type == "ad" {
                    newItem.newWidth = item.width
                } else {
                    newItem.newWidth = round((item.originalWidth * CGFloat(height)) / max(item.originalHeight, 1))
                }

                itemsInRow.append(newItem)

                let totalWidth = itemsInRow.reduce(0) { $0 + $1.newWidth }
                    + CGFloat(max(itemsInRow.count - 1, 0)) * horizontalSpacing
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

        let nonAdItems = optimizedRow.filter { $0.type != "ad" }
        let adjustmentPerItem = nonAdItems.isEmpty ? 0 : minimumChange / CGFloat(nonAdItems.count)

        for index in optimizedRow.indices {
            if optimizedRow[index].type == "ad" {
                optimizedRow[index].width = optimizedRow[index].newWidth
            } else {
                optimizedRow[index].width = optimizedRow[index].newWidth + adjustmentPerItem
            }
            optimizedRow[index].height = optimalRowHeight
        }

        if let adIndex, nonAdItems.count != optimizedRow.count {
            let itemsBelowMinWidth = nonAdItems.filter { $0.width < CGFloat(itemMinWidth) }

            if !itemsBelowMinWidth.isEmpty {
                for index in optimizedRow.indices where optimizedRow[index].type != "ad" && optimizedRow[index].width < CGFloat(itemMinWidth) {
                    optimizedRow[index].width = CGFloat(itemMinWidth)
                }

                let newRowWidth = optimizedRow.reduce(0) { $0 + $1.width }
                    + CGFloat(max(optimizedRow.count - 1, 0)) * horizontalSpacing

                if newRowWidth > containerWidth {
                    var adItem = optimizedRow[adIndex]
                    let minAdWidth = adItem.width * (100 - CGFloat(adMaxResizePercent)) / 100
                    var resizedAdWidth = adItem.width - (newRowWidth - containerWidth)

                    if resizedAdWidth < minAdWidth {
                        let adWidthDifference = minAdWidth - resizedAdWidth
                        for index in optimizedRow.indices where optimizedRow[index].type != "ad" && optimizedRow[index].width == CGFloat(itemMinWidth) {
                            optimizedRow[index].width -= adWidthDifference / CGFloat(max(itemsBelowMinWidth.count, 1))
                        }
                        resizedAdWidth = minAdWidth
                    }

                    let scaleFactor = resizedAdWidth / max(adItem.width, 1)
                    adItem.height *= scaleFactor
                    adItem.width = resizedAdWidth
                    adItem.newWidth = resizedAdWidth
                    optimizedRow[adIndex] = adItem

                    for index in optimizedRow.indices where optimizedRow[index].type != "ad" {
                        optimizedRow[index].height = adItem.height
                    }

                    optimalRowHeight = adItem.height
                }
            }
        }

        return (optimizedRow, optimalRowHeight)
    }
}

private extension KlipyMedia {
    var layoutDimensions: CGSize {
        if type == .clip,
           let width = fileMeta?.gif?.width ?? fileMeta?.webp?.width,
           let height = fileMeta?.gif?.height ?? fileMeta?.webp?.height,
           width > 0,
           height > 0 {
            return CGSize(width: width, height: height)
        }

        if let asset = file?.sm?.gif ?? file?.sm?.webp ?? file?.sm?.jpg ?? file?.xs?.gif ?? file?.xs?.webp ?? file?.xs?.jpg,
           let width = asset.width,
           let height = asset.height,
           width > 0,
           height > 0 {
            return CGSize(width: width, height: height)
        }

        let fallbackHeight: CGFloat = 100
        return CGSize(width: max(displayAspectRatio, 0.1) * fallbackHeight, height: fallbackHeight)
    }
}

private extension KlipyAdvertisement {
    var layoutDimensions: CGSize {
        CGSize(
            width: CGFloat(max(width ?? 320, 1)),
            height: CGFloat(max(height ?? 100, 1))
        )
    }
}
