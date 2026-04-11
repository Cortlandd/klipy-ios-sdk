//
//  KlipyClientStickerTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/23/25.
//

import XCTest
@testable import KlipyCore

/// Integration-style tests for the Sticker-specific convenience
/// wrappers defined in `KlipyClient+Sticker.swift`.
final class KlipyClientStickerConvenienceTests: XCTestCase {

    func testSearchStickersReturnsPage() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        // When
        let page = try await client.searchStickers(
            query: "hello",
            page: 1,
            perPage: 5,
            locale: "en-US",
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
    
    func testTrendingStickersReturnsPage() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        // When
        let page = try await client.trendingStickers(
            page: 1,
            perPage: 5,
            locale: "en-US",
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
    
    func testStickerFetchesItemBySlugFromTrending() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        let trending = try await client.trendingStickers(
            page: 1,
            perPage: 1,
            locale: "en-US",
        )
        
        guard let first = trending.data.first else {
            XCTFail("No trending stickers returned – cannot test sticker(slug:)")
            return
        }
        
        // When
        let fetched = try await client.sticker(slug: first.slug)
        
        // Then
        XCTAssertEqual(fetched.slug, first.slug)
        XCTAssertEqual(fetched.id, first.id)
    }
    
    func testStickerCategoriesNotEmpty() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        // When
        let categories = try await client.stickerCategories()
        
        // Then
        XCTAssertFalse(categories.isEmpty, "Expected at least one sticker category")
    }
}
