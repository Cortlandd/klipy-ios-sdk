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

    func testSearchClipsReturnsPage() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        // When
        let page = try await client.searchClips(
            query: "funny",
            page: 1,
            perPage: 5,
            locale: "en-US",
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
    
    func testTrendingClipsReturnsPage() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        // When
        let page = try await client.trendingClips(
            page: 1,
            perPage: 5,
            locale: "en-US",
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
    
    func testClipFetchesItemBySlugFromTrending() async throws {
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        let trending = try await client.trendingClips(
            page: 1,
            perPage: 1,
            locale: "en-US",
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
        let client = try KlipyIntegrationTestSupport.makeLiveClient()

        // When
        let categories = try await client.clipCategories()
        
        // Then
        XCTAssertFalse(categories.isEmpty, "Expected at least one clip category")
    }
}
