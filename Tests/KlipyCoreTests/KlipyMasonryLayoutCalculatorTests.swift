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

    func testThreeSquareMediaItemsFillTheContainerWidth() {
        let calculator = KlipyMasonryLayoutCalculator(
            containerWidth: 300,
            horizontalSpacing: 1,
            minRowHeight: 50,
            maxRowHeight: 180,
            maxItemsPerRow: 4
        )

        let rows = calculator.createRows(
            from: [
                .media(makeMedia(id: "1", width: 200, height: 200)),
                .media(makeMedia(id: "2", width: 200, height: 200)),
                .media(makeMedia(id: "3", width: 200, height: 200))
            ],
            metadata: KlipyPageMeta(itemMinWidth: 50, adMaxResizePercent: 20)
        )

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].items.count, 3)

        let lastItem = try XCTUnwrap(rows[0].items.last)
        XCTAssertEqual(lastItem.xPosition + lastItem.width, 300, accuracy: 0.5)
    }

    func testAdvertisementInThirdPositionStartsTheNextRow() {
        let advertisement = KlipyAdvertisement(content: "https://klipy.com/ad/1", width: 320, height: 100)
        let calculator = KlipyMasonryLayoutCalculator(
            containerWidth: 320,
            horizontalSpacing: 1,
            minRowHeight: 50,
            maxRowHeight: 180,
            maxItemsPerRow: 4
        )

        let rows = calculator.createRows(
            from: [
                .media(makeMedia(id: "1", width: 200, height: 200)),
                .media(makeMedia(id: "2", width: 180, height: 180)),
                .advertisement(advertisement),
                .media(makeMedia(id: "3", width: 220, height: 220))
            ],
            metadata: KlipyPageMeta(itemMinWidth: 50, adMaxResizePercent: 20)
        )

        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].items.count, 2)
        XCTAssertEqual(rows[1].items.first?.contentItem, .advertisement(advertisement))
    }

    func testAdvertisementKeepsItsDeclaredHeightWhenLeadingARow() {
        let calculator = KlipyMasonryLayoutCalculator(
            containerWidth: 320,
            horizontalSpacing: 1,
            minRowHeight: 50,
            maxRowHeight: 180,
            maxItemsPerRow: 4
        )

        let rows = calculator.createRows(
            from: [
                .advertisement(KlipyAdvertisement(content: "https://klipy.com/ad/1", width: 320, height: 100)),
                .media(makeMedia(id: "1", width: 220, height: 220))
            ],
            metadata: KlipyPageMeta(itemMinWidth: 50, adMaxResizePercent: 20)
        )

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].height, 100, accuracy: 0.5)
        XCTAssertEqual(rows[0].items[0].height, 100, accuracy: 0.5)
        XCTAssertEqual(rows[0].items[1].height, 100, accuracy: 0.5)
    }

    func testAdvertisementUsesDefaultBannerAspectRatioWhenDimensionsAreMissing() {
        let advertisement = KlipyAdvertisement(content: "https://klipy.com/ad/1")

        XCTAssertEqual(advertisement.displayAspectRatio, 3.2, accuracy: 0.001)
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
