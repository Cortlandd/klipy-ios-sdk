//
//  KlipyClientMemeTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/23/25.
//

import XCTest
@testable import KlipyCore

/// Integration-style tests for the Meme-specific convenience
/// wrappers defined in `KlipyClient+Meme.swift`.
final class KlipyClientMemeConvenienceTests: XCTestCase {

    func testSearchMemesReturnsPage() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        // When
        let page = try await client.searchMemes(
            query: "funny",
            page: 1,
            perPage: 5,
            locale: "en-US",
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
    
    func testTrendingMemesReturnsPage() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        // When
        let page = try await client.trendingMemes(
            page: 1,
            perPage: 5,
            locale: "en-US",
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
    
    func testMemeFetchesItemBySlugFromTrending() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        let trending = try await client.trendingMemes(
            page: 1,
            perPage: 1,
            locale: "en-US",
        )
        
        guard let first = trending.data.first else {
            XCTFail("No trending memes returned – cannot test meme(slug:)")
            return
        }
        
        // When
        let fetched = try await client.meme(slug: first.slug)
        
        // Then
        XCTAssertEqual(fetched.slug, first.slug)
        XCTAssertEqual(fetched.id, first.id)
    }
    
    func testMemeCategoriesNotEmpty() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        // When
        let categories = try await client.memeCategories()
        
        // Then
        XCTAssertFalse(categories.isEmpty, "Expected at least one meme category")
    }
}
