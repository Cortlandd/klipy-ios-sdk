//
//  KlipyClientContentFeedTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import XCTest
@testable import KlipyCore
@preconcurrency import Mocker

final class KlipyClientContentFeedTests: XCTestCase {

    private var client: KlipyClient!
    private let apiKey = "test-api-key"
    private let customerId = "user-123"

    override func setUp() {
        super.setUp()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockingURLProtocol.self]
        let session = URLSession(configuration: config)

        client = KlipyClient(
            configuration: .init(apiKey: apiKey),
            customerId: customerId,
            urlSession: session
        )
        Mocker.mode = .optin
    }

    override func tearDown() {
        Mocker.removeAll()
        client = nil
        super.tearDown()
    }

    func testTrendingContentPreservesAdvertisementsInFeedOrder() async throws {
        let url = URL(string: "https://api.klipy.com/api/v1/\(apiKey)/gifs/trending")!
        let responseBody = """
        {
          "result": true,
          "data": {
            "data": [
              { "id": "1", "slug": "wave", "type": "gif", "title": "Wave" },
              { "content": "https://klipy.com/advertisement/example", "width": 320, "height": 100, "type": "ad" },
              { "id": "2", "slug": "party", "type": "gif", "title": "Party" }
            ],
            "meta": {
              "item_min_width": 110,
              "ad_max_resize_percent": 30
            },
            "current_page": 1,
            "per_page": 24,
            "has_next": false
          }
        }
        """.data(using: .utf8)!

        let mock = Mock(
            url: url,
            ignoreQuery: true,
            contentType: .json,
            statusCode: 200,
            data: [.get: responseBody]
        )
        mock.register()

        let page = try await client.trendingContent(kind: .gif, page: 1, perPage: 24, locale: "en-US")

        XCTAssertEqual(page.data.count, 3)
        XCTAssertEqual(page.data[0].media?.slug, "wave")
        XCTAssertEqual(page.data[1].advertisement?.content, "https://klipy.com/advertisement/example")
        XCTAssertEqual(page.data[2].media?.slug, "party")
        XCTAssertEqual(page.meta?.itemMinWidth, 110)
        XCTAssertEqual(page.meta?.adMaxResizePercent, 30)
    }

    func testLegacyTrendingAPIFiltersAdvertisementsOutOfMediaResults() async throws {
        let url = URL(string: "https://api.klipy.com/api/v1/\(apiKey)/gifs/trending")!
        let responseBody = """
        {
          "result": true,
          "data": {
            "data": [
              { "id": "1", "slug": "wave", "type": "gif", "title": "Wave" },
              { "content": "https://klipy.com/advertisement/example", "width": 320, "height": 100, "type": "ad" },
              { "id": "2", "slug": "party", "type": "gif", "title": "Party" }
            ],
            "current_page": 1,
            "per_page": 24,
            "has_next": false
          }
        }
        """.data(using: .utf8)!

        let mock = Mock(
            url: url,
            ignoreQuery: true,
            contentType: .json,
            statusCode: 200,
            data: [.get: responseBody]
        )
        mock.register()

        let page = try await client.trending(kind: .gif, page: 1, perPage: 24, locale: "en-US")

        XCTAssertEqual(page.data.map(\.slug), ["wave", "party"])
        XCTAssertEqual(page.meta?.itemMinWidth, 110)
        XCTAssertEqual(page.meta?.adMaxResizePercent, 30)
    }

    func testSearchContentPreservesAdvertisementsInFeedOrder() async throws {
        let url = URL(string: "https://api.klipy.com/api/v1/\(apiKey)/gifs/search")!
        let responseBody = """
        {
          "result": true,
          "data": {
            "data": [
              { "id": "10", "slug": "cheer", "type": "gif", "title": "Cheer" },
              { "content": "https://klipy.com/advertisement/search-example", "width": 320, "height": 50, "type": "ad" },
              { "id": "11", "slug": "celebrate", "type": "gif", "title": "Celebrate" }
            ],
            "current_page": 1,
            "per_page": 24,
            "has_next": false
          }
        }
        """.data(using: .utf8)!

        let mock = Mock(
            url: url,
            ignoreQuery: true,
            contentType: .json,
            statusCode: 200,
            data: [.get: responseBody]
        )
        mock.register()

        let page = try await client.searchContent(kind: .gif, query: "celebrate", page: 1, perPage: 24, locale: "en-US")

        XCTAssertEqual(page.data.count, 3)
        XCTAssertEqual(page.data[0].media?.slug, "cheer")
        XCTAssertEqual(page.data[1].advertisement?.content, "https://klipy.com/advertisement/search-example")
        XCTAssertEqual(page.data[2].media?.slug, "celebrate")
    }
}
