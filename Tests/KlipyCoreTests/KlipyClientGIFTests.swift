//
//  KlipyClientGIFTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/23/25.
//

import XCTest
@testable import KlipyCore

/// Integration-style tests for the GIF-specific convenience
/// wrappers defined in `KlipyClient+GIF.swift`.
final class KlipyClientGIFTests: XCTestCase {
    
    private var client: KlipyClient!
    
    /// Sample API key for hitting the live Klipy API.
    /// In a real app, do not commit real production keys to source control.
    private let apiKey = "wx4NS4jKDijkRGIrNvsuSRAzCm2ZQYVfBIHUU951ZPOHRBDD8OQkoNqjO16UgW1W"
    
    override func setUp() {
        super.setUp()
        client = KlipyClient.live(apiKey: apiKey)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testSearchGIFsReturnsPage() async throws {
        // Given
        let customerId = "test-user-\(UUID().uuidString)"
        
        // When
        let page = try await client.searchGIFs(
            query: "hello",
            page: 1,
            perPage: 5,
            locale: "en-US",
            customerId: customerId
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
    
    func testTrendingGIFsReturnsPage() async throws {
        // Given
        let customerId = "test-user-\(UUID().uuidString)"
        
        // When
        let page = try await client.trendingGIFs(
            page: 1,
            perPage: 5,
            locale: "en-US",
            customerId: customerId
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
    
    func testGifFetchesItemBySlugFromTrending() async throws {
        // Given
        let customerId = "test-user-\(UUID().uuidString)"
        
        let trending = try await client.trendingGIFs(
            page: 1,
            perPage: 1,
            locale: "en-US",
            customerId: customerId
        )
        
        guard let first = trending.data.first else {
            XCTFail("No trending GIFs returned – cannot test gif(slug:)")
            return
        }
        
        // When
        let fetched = try await client.gif(slug: first.slug)
        
        // Then
        XCTAssertEqual(fetched.slug, first.slug)
        XCTAssertEqual(fetched.id, first.id)
    }
    
    func testGifCategoriesNotEmpty() async throws {
        // When
        let categories = try await client.gifCategories()
        
        // Then
        XCTAssertFalse(categories.isEmpty, "Expected at least one GIF category")
    }
}
