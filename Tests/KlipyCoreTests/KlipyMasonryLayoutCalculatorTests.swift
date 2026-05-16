//
//  KlipyMasonryLayoutCalculatorTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import XCTest
@testable import KlipyCore
@testable import KlipyUI

final class KlipyMasonryLayoutCalculatorTests: XCTestCase {

    func testCalculatorLetsAdvertisementsBecomeStandaloneBannerRows() {
        let items: [KlipyContentItem] = [
            .media(makeMedia(id: "1", width: 220, height: 220)),
            .media(makeMedia(id: "2", width: 220, height: 220)),
            .advertisement(KlipyAdvertisement(content: "https://klipy.com/ad/1", width: 320, height: 100)),
            .media(makeMedia(id: "3", width: 220, height: 180))
        ]

        let rows = KlipyMasonryLayoutCalculator(
            containerWidth: 360,
            spacing: 2,
            rowHeightRange: 92...190,
            maxItemsPerRow: 3,
            metadata: KlipyPageMeta(itemMinWidth: 100, adMaxResizePercent: 30)
        ).makeRows(items: items)

        XCTAssertEqual(rows.count, 3)
        XCTAssertEqual(rows.first?.items.count, 2)
        XCTAssertNotNil(rows.first?.items[0].item.media)
        XCTAssertNotNil(rows.first?.items[1].item.media)
        XCTAssertEqual(rows[1].items.count, 1)
        XCTAssertNotNil(rows[1].items[0].item.advertisement)
        XCTAssertEqual(rows[1].items[0].width, 320, accuracy: 1)
    }

    func testCalculatorRespectsMinimumTileWidthFromFeedMetadata() {
        let items: [KlipyContentItem] = [
            .media(makeMedia(id: "1", width: 200, height: 200)),
            .media(makeMedia(id: "2", width: 200, height: 200)),
            .media(makeMedia(id: "3", width: 200, height: 200)),
            .media(makeMedia(id: "4", width: 200, height: 200))
        ]

        let rows = KlipyMasonryLayoutCalculator(
            containerWidth: 320,
            spacing: 8,
            rowHeightRange: 92...190,
            maxItemsPerRow: 4,
            metadata: KlipyPageMeta(itemMinWidth: 100, adMaxResizePercent: nil)
        ).makeRows(items: items)

        XCTAssertFalse(rows.isEmpty)
        XCTAssertTrue(rows.flatMap(\.items).allSatisfy { $0.width >= 100 })
    }

    private func makeMedia(id: String, width: Int, height: Int) -> KlipyMedia {
        KlipyMedia(
            id: id,
            slug: id,
            type: .gif,
            title: id,
            fileMeta: KlipyMediaFileMeta(
                mp4: nil,
                gif: KlipyMediaFileMetaEntry(width: width, height: height),
                webp: KlipyMediaFileMetaEntry(width: width, height: height)
            )
        )
    }
}
