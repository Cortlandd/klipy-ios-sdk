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

    func testCanonicalShareURLsUseThePublicExploreRoutes() {
        XCTAssertEqual(
            KlipyMediaType.gif.canonicalShareURL(for: "wave-hi").absoluteString,
            "https://klipy.com/explore/gifs/wave-hi"
        )
        XCTAssertEqual(
            KlipyMediaType.sticker.canonicalShareURL(for: "thumbs-up").absoluteString,
            "https://klipy.com/explore/stickers/thumbs-up"
        )
        XCTAssertEqual(
            KlipyMediaType.clip.canonicalShareURL(for: "party-time").absoluteString,
            "https://klipy.com/explore/clips/party-time"
        )
    }

    func testMediaCanonicalShareURLDelegatesToItsMediaType() {
        let media = KlipyMedia(id: "1", slug: "hello-there", type: .emoji, title: "Hello")
        XCTAssertEqual(
            media.canonicalShareURL.absoluteString,
            "https://klipy.com/explore/emojis/hello-there"
        )
    }
}
