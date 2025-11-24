//
//  KlipyClient+Ads.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation
import UIKit

/// Parameters used to request an ad-aware Recent feed.
public struct KlipyAdParameters: Sendable {
    public var minWidth: Int
    public var maxWidth: Int
    public var minHeight: Int
    public var maxHeight: Int
    public var language: String?
    public var userAgent: String?

    public init(
        minWidth: Int,
        maxWidth: Int,
        minHeight: Int,
        maxHeight: Int,
        language: String? = nil,
        userAgent: String? = nil
    ) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.language = language
        self.userAgent = userAgent
    }

    /// Builds the query parameters Klipy expects, e.g. `ad-min-width`, etc.
    public var asQueryParameters: [String: String] {
        var params: [String: String] = [
            "ad-min-width": String(minWidth),
            "ad-max-width": String(maxWidth),
            "ad-min-height": String(minHeight),
            "ad-max-height": String(maxHeight)
        ]
        if let language { params["ad-language"] = language }
        if let userAgent { params["ad-user-agent"] = userAgent }
        return params
    }
}

public extension KlipyClient {
    /// Recent items including ad placement metadata for a given media type.
    ///
    /// Internally just passes `adParams` into the generic `recent` method.
    func recentWithAds(
        kind: KlipyMediaType,
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil,
        adParameters: KlipyAdParameters
    ) async throws -> KlipyPage<KlipyMedia> {
        try await recent(
            kind: kind,
            page: page,
            perPage: perPage,
            locale: locale,
            adParams: adParameters.asQueryParameters
        )
    }
}
