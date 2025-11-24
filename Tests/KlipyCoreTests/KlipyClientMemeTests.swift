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
    
    private var client: KlipyClient!
    
    /// Sample API key for hitting the live Klipy API.
    private let apiKey = "wx4NS4jKDijkRGIrNvsuSRAzCm2ZQYVfBIHUU951ZPOHRBDD8OQkoNqjO16UgW1W"
    
    override func setUp() {
        super.setUp()
        client = KlipyClient.live(apiKey: apiKey)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testSearchMemesReturnsPage() async throws {
        
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
        // When
        let categories = try await client.memeCategories()
        
        // Then
        XCTAssertFalse(categories.isEmpty, "Expected at least one meme category")
    }
}
