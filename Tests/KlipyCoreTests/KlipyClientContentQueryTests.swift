//
//  KlipyClientContentQueryTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import XCTest
@testable import KlipyCore
@preconcurrency import Mocker

final class KlipyClientContentQueryTests: XCTestCase {

    private var client: KlipyClient!
    private let apiKey = "test-api-key"
    private let customerId = "user-123"

    override func setUp() {
        super.setUp()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockingURLProtocol.self]
        let session = URLSession(configuration: config)

        let klipyConfig = KlipyConfiguration(apiKey: apiKey)
        client = KlipyClient(configuration: klipyConfig, customerId: customerId, urlSession: session)
        Mocker.mode = .optin
    }

    override func tearDown() {
        Mocker.removeAll()
        client = nil
        super.tearDown()
    }

    func testSearchAddsAdFrameToContentRequests() async throws {
        let url = URL(string: "https://api.klipy.com/api/v1/\(apiKey)/gifs/search")!
        let responseBody = """
        { "result": true, "data": { "data": [], "current_page": 1, "per_page": 24, "has_next": false } }
        """.data(using: .utf8)!

        var mock = Mock(
            url: url,
            ignoreQuery: true,
            contentType: .json,
            statusCode: 200,
            data: [.get: responseBody]
        )

        mock.onRequestHandler = OnRequestHandler(httpBodyType: Data.self) { request, _ in
            let queryItems = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []
            let query = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(query["ad-frame"], "1")
            XCTAssertEqual(query["customer_id"], self.customerId)
            XCTAssertEqual(query["q"], "party")
            XCTAssertEqual(query["page"], "1")
            XCTAssertEqual(query["per_page"], "24")
            XCTAssertEqual(query["locale"], "en-US")
        }

        let requestExpectation = expectationForRequestingMock(&mock)
        let completionExpectation = expectationForCompletingMock(&mock)
        mock.register()

        _ = try await client.searchGIFs(query: "party", page: 1, perPage: 24, locale: "en-US")

        await fulfillment(
            of: [requestExpectation, completionExpectation],
            timeout: 2.0,
            enforceOrder: false
        )
    }

    func testRecentPreservesAdParametersAndAddsAdFrame() async throws {
        let url = URL(string: "https://api.klipy.com/api/v1/\(apiKey)/gifs/recent/\(customerId)")!
        let responseBody = """
        { "result": true, "data": { "data": [], "current_page": 1, "per_page": 24, "has_next": false } }
        """.data(using: .utf8)!

        var mock = Mock(
            url: url,
            ignoreQuery: true,
            contentType: .json,
            statusCode: 200,
            data: [.get: responseBody]
        )

        mock.onRequestHandler = OnRequestHandler(httpBodyType: Data.self) { request, _ in
            let queryItems = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []
            let query = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(query["ad-frame"], "1")
            XCTAssertEqual(query["ad-min-width"], "320")
            XCTAssertEqual(query["ad-max-height"], "250")
        }

        let requestExpectation = expectationForRequestingMock(&mock)
        let completionExpectation = expectationForCompletingMock(&mock)
        mock.register()

        _ = try await client.recent(
            kind: .gif,
            page: 1,
            perPage: 24,
            locale: "en-US",
            adParams: [
                "ad-min-width": "320",
                "ad-max-height": "250"
            ]
        )

        await fulfillment(
            of: [requestExpectation, completionExpectation],
            timeout: 2.0,
            enforceOrder: false
        )
    }

    func testItemAddsAdFrameToSingleContentRequests() async throws {
        let slug = "hello-hi-662"
        let url = URL(string: "https://api.klipy.com/api/v1/\(apiKey)/gifs/\(slug)")!
        let responseBody = """
        { "result": true, "data": { "id": "1", "slug": "\(slug)", "type": "gif", "title": "Hello" } }
        """.data(using: .utf8)!

        var mock = Mock(
            url: url,
            ignoreQuery: true,
            contentType: .json,
            statusCode: 200,
            data: [.get: responseBody]
        )

        mock.onRequestHandler = OnRequestHandler(httpBodyType: Data.self) { request, _ in
            let queryItems = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []
            let query = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(query["ad-frame"], "1")
        }

        let requestExpectation = expectationForRequestingMock(&mock)
        let completionExpectation = expectationForCompletingMock(&mock)
        mock.register()

        _ = try await client.gif(slug: slug)

        await fulfillment(
            of: [requestExpectation, completionExpectation],
            timeout: 2.0,
            enforceOrder: false
        )
    }
}
