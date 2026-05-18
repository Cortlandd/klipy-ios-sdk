//
//  KlipyPickerConfig.swift
//  KlipySDK
//
//  Created by Cortland Walker on 4/11/26.
//

import Foundation

/// Configuration for `KlipyPickerView`.
///
/// Use this to control which tabs are available, how dense the media feed is,
/// and what the picker should load when the search query is empty.
public struct KlipyPickerConfig: Equatable, Sendable {
    /// Tabs to show in the picker.
    public var mediaTabs: [KlipyPickerMediaTab]

    /// The maximum number of items the picker feed will try to place in a row.
    ///
    /// The picker now uses a masonry feed rather than a strict grid,
    /// so this value controls feed density instead of a fixed column count.
    public var maxItemsPerRow: Int

    /// Optional locale override used for search, trending, and recents.
    public var locale: String?

    /// Whether to use recents when the search query is empty.
    public var showRecents: Bool

    /// Whether to use trending when the search query is empty.
    /// If both `showTrending` and `showRecents` are `true`,
    /// trending is used as the default feed.
    public var showTrending: Bool

    /// The initial tab to select when the picker opens.
    public var initialTab: KlipyPickerMediaTab

    /// Whether selecting a media item should first show a confirmation screen.
    public var showConfirmationScreen: Bool

    /// Visual styling for the picker.
    public var theme: KlipyTheme

    public init(
        mediaTabs: [KlipyPickerMediaTab] = [.gifs, .stickers, .clips, .memes, .emojis],
        maxItemsPerRow: Int = 3,
        locale: String? = nil,
        showRecents: Bool = false,
        showTrending: Bool = true,
        initialTab: KlipyPickerMediaTab = .gifs,
        showConfirmationScreen: Bool = false,
        theme: KlipyTheme = .automatic
    ) {
        self.mediaTabs = mediaTabs
        self.maxItemsPerRow = max(2, maxItemsPerRow)
        self.locale = locale
        self.showRecents = showRecents
        self.showTrending = showTrending
        self.initialTab = initialTab
        self.showConfirmationScreen = showConfirmationScreen
        self.theme = theme
    }

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
