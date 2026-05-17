//
//  KlipyUIKitBridgeTests.swift
//  KlipySDK
//
//  Created by Codex on 5/16/26.
//

import XCTest
@testable import KlipyCore
@testable import KlipyUI

@MainActor
final class KlipyUIKitBridgeTests: XCTestCase {
    func testPickerViewControllerNotifiesDelegateOnSelection() {
        let controller = KlipyPickerViewController(
            client: KlipyClient(configuration: .init(apiKey: "demo-key"))
        )
        let delegate = PickerDelegateSpy()
        let media = KlipyMedia(id: "1", slug: "hello", type: .gif, title: "Hello")

        controller.delegate = delegate
        controller.loadViewIfNeeded()
        controller.handleSelection(media)

        XCTAssertEqual(delegate.selectedMedia?.id, "1")
        XCTAssertFalse(delegate.didClose)
    }

    func testPickerViewControllerNotifiesDelegateOnClose() {
        let controller = KlipyPickerViewController(
            client: KlipyClient(configuration: .init(apiKey: "demo-key"))
        )
        let delegate = PickerDelegateSpy()

        controller.delegate = delegate
        controller.loadViewIfNeeded()
        controller.handleClose()

        XCTAssertTrue(delegate.didClose)
    }

    func testMediaViewUpdatesConfiguredMedia() {
        let first = KlipyMedia(id: "1", slug: "wave", type: .gif, title: "Wave")
        let second = KlipyMedia(id: "2", slug: "party", type: .sticker, title: "Party")
        let mediaView = KlipyMediaView(media: first)

        XCTAssertEqual(mediaView.media?.id, "1")
        XCTAssertEqual(mediaView.subviews.count, 1)

        mediaView.configure(with: second)

        XCTAssertEqual(mediaView.media?.id, "2")
        XCTAssertEqual(mediaView.subviews.count, 1)
    }
}

@MainActor
private final class PickerDelegateSpy: KlipyPickerViewControllerDelegate {
    private(set) var selectedMedia: KlipyMedia?
    private(set) var didClose = false

    func klipyPickerViewController(_ controller: KlipyPickerViewController, didSelect media: KlipyMedia) {
        selectedMedia = media
    }

    func klipyPickerViewControllerDidClose(_ controller: KlipyPickerViewController) {
        didClose = true
    }
}
