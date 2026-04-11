//
//  KlipyClientEmojiTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 4/11/26.
//

import XCTest
@testable import KlipyCore

final class KlipyClientEmojiTests: XCTestCase {

    private var client: KlipyClient!
    private let apiKey = "wx4NS4jKDijkRGIrNvsuSRAzCm2ZQYVfBIHUU951ZPOHRBDD8OQkoNqjO16UgW1W"

    override func setUp() {
        super.setUp()
        client = KlipyClient.live(apiKey: apiKey)
    }

    override func tearDown() {
        client = nil
        super.tearDown()
    }

    func testSearchEmojisReturnsPage() async throws {
        let page = try await client.searchEmojis(
            query: "smile",
            page: 1,
            perPage: 5,
            locale: "en-US"
        )

        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }

    func testTrendingEmojisReturnsPage() async throws {
        let page = try await client.trendingEmojis(
            page: 1,
            perPage: 5,
            locale: "en-US"
        )

        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }

    func testEmojiFetchesItemBySlugFromTrending() async throws {
        let trending = try await client.trendingEmojis(
            page: 1,
            perPage: 1,
            locale: "en-US"
        )

        guard let first = trending.data.first else {
            XCTFail("No trending emojis returned – cannot test emoji(slug:)")
            return
        }

        let fetched = try await client.emoji(slug: first.slug)

        XCTAssertEqual(fetched.slug, first.slug)
        XCTAssertEqual(fetched.id, first.id)
    }

    func testEmojiCategoriesNotEmpty() async throws {
        let categories = try await client.emojiCategories()
        XCTAssertFalse(categories.isEmpty, "Expected at least one emoji category")
    }
}
