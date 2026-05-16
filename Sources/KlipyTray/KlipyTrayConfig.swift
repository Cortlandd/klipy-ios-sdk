//
//  KlipyTrayConfig.swift
//  KlipySDK
//
//  Created by Cortland Walker on 12/17/25.
//

import Foundation
import KlipyUI

/// Configuration for the Klipy Tray (keyboard-like panel).
public struct KlipyTrayConfig: Equatable, Sendable {
    /// Tabs to show (GIF / Stickers / Clips / Memes / Emojis).
    public var mediaTabs: [KlipyPickerMediaTab]

    /// The initial tab to select.
    public var initialTab: KlipyPickerMediaTab

    /// The maximum number of items the tray feed will try to place in a row.
    ///
    /// The tray uses the same masonry feed as the standalone picker,
    /// so this controls feed density instead of a strict grid column count.
    public var maxItemsPerRow: Int

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
        mediaTabs: [KlipyPickerMediaTab] = [.gifs, .stickers, .clips, .memes, .emojis],
        initialTab: KlipyPickerMediaTab = .gifs,
        maxItemsPerRow: Int = 3,
        showTrending: Bool = true,
        showRecents: Bool = false,
        showCategories: Bool = false,
        showSearch: Bool = true,
        brandURL: URL? = URL(string: "https://klipy.com")
    ) {
        self.mediaTabs = mediaTabs
        self.initialTab = initialTab
        self.maxItemsPerRow = max(2, maxItemsPerRow)
        self.showTrending = showTrending
        self.showRecents = showRecents
        self.showCategories = showCategories
        self.showSearch = showSearch
        self.brandURL = brandURL
    }

    @available(*, deprecated, renamed: "maxItemsPerRow", message: "The tray uses a masonry feed now, so this value controls feed density instead of a strict grid column count.")
    public var columns: Int {
        get { maxItemsPerRow }
        set { maxItemsPerRow = max(2, newValue) }
    }

    @available(*, deprecated, message: "Use init(mediaTabs:initialTab:maxItemsPerRow:showTrending:showRecents:showCategories:showSearch:brandURL:) instead.")
    public init(
        mediaTabs: [KlipyPickerMediaTab],
        initialTab: KlipyPickerMediaTab,
        columns: Int,
        showTrending: Bool,
        showRecents: Bool,
        showCategories: Bool,
        showSearch: Bool,
        brandURL: URL?
    ) {
        self.init(
            mediaTabs: mediaTabs,
            initialTab: initialTab,
            maxItemsPerRow: columns,
            showTrending: showTrending,
            showRecents: showRecents,
            showCategories: showCategories,
            showSearch: showSearch,
            brandURL: brandURL
        )
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
