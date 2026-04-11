//
//  KlipyPickerConfig.swift
//  KlipySDK
//
//  Created by Cortland Walker on 4/11/26.
//

import Foundation

/// Configuration for `KlipyPickerView`.
///
/// Use this to control which tabs are available, how the grid is laid out,
/// and what the picker should load when the search query is empty.
public struct KlipyPickerConfig: Equatable, Sendable {
    /// Tabs to show in the picker.
    public var mediaTabs: [KlipyPickerMediaTab]

    /// Number of columns to use in the picker grid.
    public var columns: Int

    /// Whether to use recents when the search query is empty.
    public var showRecents: Bool

    /// Whether to use trending when the search query is empty.
    /// If both `showTrending` and `showRecents` are `true`,
    /// trending is used as the default feed.
    public var showTrending: Bool

    /// The initial tab to select when the picker opens.
    public var initialTab: KlipyPickerMediaTab

    public init(
        mediaTabs: [KlipyPickerMediaTab] = [.gifs, .stickers, .clips, .memes, .emojis],
        columns: Int = 3,
        showRecents: Bool = false,
        showTrending: Bool = true,
        initialTab: KlipyPickerMediaTab = .gifs
    ) {
        self.mediaTabs = mediaTabs
        self.columns = max(2, columns)
        self.showRecents = showRecents
        self.showTrending = showTrending
        self.initialTab = initialTab
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
