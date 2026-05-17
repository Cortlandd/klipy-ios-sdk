//
//  KlipyUIConfigurationTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/16/26.
//

import XCTest
@testable import KlipyUI
@testable import KlipyTray

final class KlipyUIConfigurationTests: XCTestCase {
    func testPickerConfigSupportsThemeLocaleAndConfirmationOptions() {
        let config = KlipyPickerConfig(
            mediaTabs: [.gifs, .clips],
            maxItemsPerRow: 4,
            locale: "es-ES",
            showRecents: true,
            showTrending: false,
            initialTab: .clips,
            showConfirmationScreen: true,
            theme: .darkBlur
        )

        XCTAssertEqual(config.mediaTabs, [.gifs, .clips])
        XCTAssertEqual(config.maxItemsPerRow, 4)
        XCTAssertEqual(config.locale, "es-ES")
        XCTAssertTrue(config.showRecents)
        XCTAssertFalse(config.showTrending)
        XCTAssertEqual(config.initialTab, .clips)
        XCTAssertTrue(config.showConfirmationScreen)
        XCTAssertEqual(config.theme, .darkBlur)
    }

    func testTrayConfigSupportsThemeAndLocaleOptions() {
        let config = KlipyTrayConfig(
            mediaTabs: [.stickers, .emojis],
            initialTab: .emojis,
            maxItemsPerRow: 4,
            locale: "fr-FR",
            showTrending: false,
            showRecents: true,
            showCategories: true,
            showSearch: false,
            brandURL: URL(string: "https://example.com"),
            theme: .lightBlur
        )

        XCTAssertEqual(config.mediaTabs, [.stickers, .emojis])
        XCTAssertEqual(config.initialTab, .emojis)
        XCTAssertEqual(config.maxItemsPerRow, 4)
        XCTAssertEqual(config.locale, "fr-FR")
        XCTAssertFalse(config.showTrending)
        XCTAssertTrue(config.showRecents)
        XCTAssertTrue(config.showCategories)
        XCTAssertFalse(config.showSearch)
        XCTAssertEqual(config.brandURL?.absoluteString, "https://example.com")
        XCTAssertEqual(config.theme, .lightBlur)
    }

    func testLegacyColumnsAliasStillControlsFeedDensity() {
        var pickerConfig = KlipyPickerConfig(maxItemsPerRow: 3)
        pickerConfig.columns = 5
        XCTAssertEqual(pickerConfig.maxItemsPerRow, 5)

        var trayConfig = KlipyTrayConfig(maxItemsPerRow: 3)
        trayConfig.columns = 4
        XCTAssertEqual(trayConfig.maxItemsPerRow, 4)
    }
}
