//
//  KlipyWebViewTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import XCTest
@testable import KlipyUI

@MainActor
final class KlipyWebViewTests: XCTestCase {
    func testNormalizedAdURLAppendsAdIframeWhenMissing() {
        let webView = KlipyWebView()

        let url = webView.normalizedAdURL(from: "https://klipy.com/advertisement/example")

        let components = URLComponents(url: try! XCTUnwrap(url), resolvingAgainstBaseURL: false)
        let query = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(query["ad-iframe"], "1")
    }

    func testNormalizedAdURLKeepsExistingAdIframeValue() {
        let webView = KlipyWebView()

        let url = webView.normalizedAdURL(from: "https://klipy.com/advertisement/example?ad-iframe=1")

        let components = URLComponents(url: try! XCTUnwrap(url), resolvingAgainstBaseURL: false)
        let iframeItems = (components?.queryItems ?? []).filter { $0.name == "ad-iframe" }
        XCTAssertEqual(iframeItems.count, 1)
        XCTAssertEqual(iframeItems.first?.value, "1")
    }
}
