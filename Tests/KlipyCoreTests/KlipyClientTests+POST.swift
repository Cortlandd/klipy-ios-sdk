//
//  KlipyClientTests+POST.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/23/25.
//

import XCTest
@testable import KlipyCore
@preconcurrency import Mocker

final class KlipyClientPostTests: XCTestCase {

    private var client: KlipyClient!
    /// Same sample key used in GET tests.
    private let apiKey = "wx4NS4jKDijkRGIrNvsuSRAzCm2ZQYVfBIHUU951ZPOHRBDD8OQkoNqjO16UgW1W"

    override func setUp() {
        super.setUp()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockingURLProtocol.self]
        let session = URLSession(configuration: config)

        let klipyConfig = KlipyConfiguration(apiKey: apiKey)
        client = KlipyClient(configuration: klipyConfig, urlSession: session)

        // opt-in so only registered mocks are intercepted
        Mocker.mode = .optin
    }

    override func tearDown() {
        Mocker.removeAll()
        client = nil
        super.tearDown()
    }

    // MARK: - Share Trigger

    func testTriggerShare_usesCorrectURLMethodAndBody() async throws {
        let slug = "hello-hi-662"
        let customerId = "user-123"
        let query = "hello"

        let url = URL(string: "https://api.klipy.com/api/v1/\(apiKey)/gifs/share/\(slug)")!

        // Response envelope KlipyClient expects
        let responseBody = """
        { "result": true, "data": {} }
        """.data(using: .utf8)!

        var mock = Mock(
            url: url,
            contentType: .json,
            statusCode: 200,
            data: [.post: responseBody]
        )

        // Verify body payload
        mock.onRequestHandler = OnRequestHandler(
            httpBodyType: [String: String].self
        ) { request, body in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(body!["customer_id"], customerId)
            XCTAssertEqual(body!["q"], query)
        }

        let requestExpectation = expectationForRequestingMock(&mock)
        let completionExpectation = expectationForCompletingMock(&mock)
        mock.register()

        try await client.triggerShare(
            kind: .gif,
            slug: slug,
            customerId: customerId,
            searchQuery: query
        )

        await fulfillment(
            of: [requestExpectation, completionExpectation],
            timeout: 2.0,
            enforceOrder: false
        )
    }

    // MARK: - Hide from Recent

    func testHideFromRecent_usesCorrectURLAndMethod() async throws {
        let customerId = "user-789"
        let slug = "hello-hi-662"

        let url = URL(string: "https://api.klipy.com/api/v1/\(apiKey)/gifs/recent/\(customerId)/\(slug)")!

        let responseBody = """
        { "result": true, "data": {} }
        """.data(using: .utf8)!

        var mock = Mock(
            url: url,
            contentType: .json,
            statusCode: 200,
            data: [.delete: responseBody]
        )

        mock.onRequestHandler = OnRequestHandler(
            httpBodyType: Data.self
        ) { request, _ in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.url, url)
        }

        let requestExpectation = expectationForRequestingMock(&mock)
        let completionExpectation = expectationForCompletingMock(&mock)
        mock.register()

        try await client.hideFromRecent(
            kind: .gif,
            customerId: customerId,
            slug: slug
        )

        await fulfillment(
            of: [requestExpectation, completionExpectation],
            timeout: 2.0,
            enforceOrder: false
        )
    }
}
