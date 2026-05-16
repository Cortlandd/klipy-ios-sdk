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

    func testAdvertisementSpansTwoColumnsInThreeColumnFeeds() {
        let span = KlipyMasonryFeedLayoutPolicy.columnSpan(
            for: .advertisement(KlipyAdvertisement(content: "https://klipy.com/ad/1", width: 220, height: 140)),
            maxItemsPerRow: 3
        )

        XCTAssertEqual(span, 2)
    }

    func testAdvertisementSpansFullWidthInTwoColumnFeeds() {
        let span = KlipyMasonryFeedLayoutPolicy.columnSpan(
            for: .advertisement(KlipyAdvertisement(content: "https://klipy.com/ad/1")),
            maxItemsPerRow: 2
        )

        XCTAssertEqual(span, 2)
    }

    func testWideBannerAdvertisementSpansFullWidthInThreeColumnFeeds() {
        let span = KlipyMasonryFeedLayoutPolicy.columnSpan(
            for: .advertisement(KlipyAdvertisement(content: "https://klipy.com/ad/1", width: 320, height: 100)),
            maxItemsPerRow: 3
        )

        XCTAssertEqual(span, 3)
    }

    func testMediaAlwaysUsesSingleColumnSpan() {
        let span = KlipyMasonryFeedLayoutPolicy.columnSpan(
            for: .media(makeMedia(id: "1", width: 220, height: 220)),
            maxItemsPerRow: 3
        )

        XCTAssertEqual(span, 1)
    }

    func testFeedFallsBackToTwoPointSpacingFromTileInset() {
        let spacing = KlipyMasonryFeedLayoutPolicy.effectiveSpacing(
            spacing: 0,
            tileInset: 1
        )

        XCTAssertEqual(spacing, 2)
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
