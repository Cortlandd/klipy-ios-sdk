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

    func testNormalizedHTMLDocumentWrapsRawHTMLInFullBleedDocument() {
        let webView = KlipyWebView()

        let document = webView.normalizedHTMLDocument(from: "<iframe src=\"https://klipy.com/ad\"></iframe>")

        XCTAssertTrue(document.contains("<!doctype html>"))
        XCTAssertTrue(document.contains("overflow: hidden !important"))
        XCTAssertTrue(document.contains("width: 100% !important"))
        XCTAssertTrue(document.contains("height: 100% !important"))
    }

    func testNormalizedHTMLDocumentKeepsExistingHTMLDocumentUnchanged() {
        let webView = KlipyWebView()
        let input = "<html><body><div>Ad</div></body></html>"

        let document = webView.normalizedHTMLDocument(from: input)

        XCTAssertEqual(document, input)
    }
}
