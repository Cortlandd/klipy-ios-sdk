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

    func testSearchGIFsReturnsPage() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        // When
        let page = try await client.searchGIFs(
            query: "hello",
            page: 1,
            perPage: 5,
            locale: "en-US",
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
    
    func testTrendingGIFsReturnsPage() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        // When
        let page = try await client.trendingGIFs(
            page: 1,
            perPage: 5,
            locale: "en-US",
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
    
    func testGifFetchesItemBySlugFromTrending() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        let trending = try await client.trendingGIFs(
            page: 1,
            perPage: 1,
            locale: "en-US",
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
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        // When
        let categories = try await client.gifCategories()
        
        // Then
        XCTAssertFalse(categories.isEmpty, "Expected at least one GIF category")
    }
}
