//
//  KlipyClientClipTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/23/25.
//

import XCTest
@testable import KlipyCore

/// Integration-style tests for the Clip-specific convenience
final class KlipyClientClipTests: XCTestCase {
    
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
    
    func testSearchClipsReturnsPage() async throws {
        // Given
        let customerId = "test-user-\(UUID().uuidString)"
        
        // When
        let page = try await client.searchClips(
            query: "funny",
            page: 1,
            perPage: 5,
            locale: "en-US",
            customerId: customerId
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
    
    func testTrendingClipsReturnsPage() async throws {
        // Given
        let customerId = "test-user-\(UUID().uuidString)"
        
        // When
        let page = try await client.trendingClips(
            page: 1,
            perPage: 5,
            locale: "en-US",
            customerId: customerId
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
    
    func testClipFetchesItemBySlugFromTrending() async throws {
        // Given
        let customerId = "test-user-\(UUID().uuidString)"
        
        let trending = try await client.trendingClips(
            page: 1,
            perPage: 1,
            locale: "en-US",
            customerId: customerId
        )
        
        guard let first = trending.data.first else {
            XCTFail("No trending clips returned – cannot test clip(slug:)")
            return
        }
        
        // When
        let fetched = try await client.clip(slug: first.slug)
        
        // Then
        XCTAssertEqual(fetched.slug, first.slug)
        XCTAssertEqual(fetched.id, first.id)
    }
    
    func testClipCategoriesNotEmpty() async throws {
        // When
        let categories = try await client.clipCategories()
        
        // Then
        XCTAssertFalse(categories.isEmpty, "Expected at least one clip category")
    }
}
