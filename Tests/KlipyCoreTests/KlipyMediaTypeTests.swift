//
//  KlipyMediaTypeTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/25/26.
//

import XCTest
@testable import KlipyCore

final class KlipyMediaTypeTests: XCTestCase {
    func testPathSegmentsMatchThePublicAPIRoutes() {
        XCTAssertEqual(KlipyMediaType.gif.pathSegment, "gifs")
        XCTAssertEqual(KlipyMediaType.sticker.pathSegment, "stickers")
        XCTAssertEqual(KlipyMediaType.clip.pathSegment, "clips")
        XCTAssertEqual(KlipyMediaType.meme.pathSegment, "static-memes")
        XCTAssertEqual(KlipyMediaType.emoji.pathSegment, "emojis")
    }
}
