//
//  KlipyAdParametersTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/23/25.
//

import XCTest
@testable import KlipyCore

/// Unit tests for the pure parameter-building logic in `KlipyAdParameters`.
final class KlipyAdParametersTests: XCTestCase {
    
    func testAsQueryParametersIncludesAllRequiredKeys() {
        // Given
        let params = KlipyAdParameters(
            minWidth: 320,
            maxWidth: 1024,
            minHeight: 50,
            maxHeight: 250,
            language: "en",
            userAgent: "KlipySDKTests/1.0"
        )
        
        // When
        let q = params.asQueryParameters
        
        // Then
        XCTAssertEqual(q["ad-min-width"], "320")
        XCTAssertEqual(q["ad-max-width"], "1024")
        XCTAssertEqual(q["ad-min-height"], "50")
        XCTAssertEqual(q["ad-max-height"], "250")
        XCTAssertEqual(q["ad-language"], "en")
        XCTAssertEqual(q["ad-user-agent"], "KlipySDKTests/1.0")
    }
    
    func testAsQueryParametersOmitsNilOptionalValues() {
        // Given
        let params = KlipyAdParameters(
            minWidth: 300,
            maxWidth: 600,
            minHeight: 90,
            maxHeight: 90,
            language: nil,
            userAgent: nil
        )
        
        // When
        let q = params.asQueryParameters
        
        // Then
        XCTAssertEqual(q["ad-min-width"], "300")
        XCTAssertEqual(q["ad-max-width"], "600")
        XCTAssertEqual(q["ad-min-height"], "90")
        XCTAssertEqual(q["ad-max-height"], "90")
        XCTAssertNil(q["ad-language"])
        XCTAssertNil(q["ad-user-agent"])
    }
}

/// Integration-style test for the `recentWithAds` wrapper.
final class KlipyClientAdsTests: XCTestCase {
    
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
    
    func testRecentWithAdsReturnsPageForGIFs() async throws {
        
        let adParams = KlipyAdParameters(
            minWidth: 320,
            maxWidth: 1024,
            minHeight: 50,
            maxHeight: 250,
            language: "en",
            userAgent: "KlipySDKTests/1.0"
        )
        
        // When
        let page = try await client.recentWithAds(
            kind: .gif,
            page: 1,
            perPage: 5,
            locale: "en-US",
            adParameters: adParams
        )
        
        // Then
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertLessThanOrEqual(page.data.count, 5)
    }
}
