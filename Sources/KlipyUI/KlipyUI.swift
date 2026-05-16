//
//  KlipyUI.swift
//  KlipySDK
//
//  Created by Cortland Walker on 4/10/26.
//

import Foundation
@_exported import KlipyCore
import KlipyCore

public protocol KlipyMediaLoading: Sendable {
    func trendingContent(
        kind: KlipyMediaType,
        page: Int?,
        perPage: Int?,
        locale: String?
    ) async throws -> KlipyPage<KlipyContentItem>

    func recentContent(
        kind: KlipyMediaType,
        page: Int?,
        perPage: Int?,
        locale: String?,
        adParams: [String: String]?
    ) async throws -> KlipyPage<KlipyContentItem>

    func searchContent(
        kind: KlipyMediaType,
        query: String,
        page: Int?,
        perPage: Int?,
        locale: String?
    ) async throws -> KlipyPage<KlipyContentItem>
}

extension KlipyClient: KlipyMediaLoading {}
