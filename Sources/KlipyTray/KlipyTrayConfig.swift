//
//  KlipyTrayConfig.swift
//  KlipySDK
//
//  Created by Cortland Walker on 12/17/25.
//

import Foundation
import KlipyUI

/// Configuration for the Klipy Tray (keyboard-like panel).
///
/// Mirrors the Android tray config so the behavior is predictable across platforms.
public struct KlipyTrayConfig: Equatable, Sendable {
    /// Tabs to show (GIF / Stickers / Clips / Memes).
    public var mediaTabs: [KlipyPickerMediaTab]

    /// The initial tab to select.
    public var initialTab: KlipyPickerMediaTab

    /// Grid column count.
    public var columns: Int

    /// When search query is empty, load trending first if enabled.
    public var showTrending: Bool

    /// When search query is empty, load recents if enabled and trending is disabled.
    public var showRecents: Bool

    /// Whether to load and show categories for the selected tab.
    public var showCategories: Bool

    /// Whether to show the search bar.
    public var showSearch: Bool
    
    /// Official Klipy website
    public var brandURL: URL? = URL(string: "https://klipy.com")

    public init(
        mediaTabs: [KlipyPickerMediaTab] = [.gifs, .stickers, .clips, .memes],
        initialTab: KlipyPickerMediaTab = .gifs,
        columns: Int = 3,
        showTrending: Bool = true,
        showRecents: Bool = false,
        showCategories: Bool = false,
        showSearch: Bool = true
    ) {
        self.mediaTabs = mediaTabs
        self.initialTab = initialTab
        self.columns = max(2, columns)
        self.showTrending = showTrending
        self.showRecents = showRecents
        self.showCategories = showCategories
        self.showSearch = showSearch
    }

    /// Feed to use when the search query is empty.
    public var emptyQueryFeed: EmptyQueryFeed {
        if showTrending { return .trending }
        if showRecents { return .recent }
        return .none
    }

    public enum EmptyQueryFeed: Equatable, Sendable {
        case trending
        case recent
        case none
    }
}
