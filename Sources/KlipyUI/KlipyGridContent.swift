//
//  KlipyGridContent.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/16/26.
//

import Foundation
import KlipyCore

public enum KlipyGridContent: Equatable, Sendable {
    case trending(kind: KlipyMediaType, locale: String? = nil)
    case recent(kind: KlipyMediaType, locale: String? = nil)
    case search(kind: KlipyMediaType, query: String, locale: String? = nil)

    var mediaType: KlipyMediaType {
        switch self {
        case let .trending(kind, _), let .recent(kind, _), let .search(kind, _, _):
            return kind
        }
    }

    var localeOverride: String? {
        switch self {
        case let .trending(_, locale), let .recent(_, locale), let .search(_, _, locale):
            return locale
        }
    }
}

public struct KlipyGridConfiguration: Equatable, Sendable {
    public var maxItemsPerRow: Int
    public var theme: KlipyTheme

    public init(
        maxItemsPerRow: Int = 3,
        theme: KlipyTheme = .automatic
    ) {
        self.maxItemsPerRow = max(2, maxItemsPerRow)
        self.theme = theme
    }

}
