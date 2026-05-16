//
//  KlipyTrayLoading.swift
//  KlipySDK
//
//  Created by Cortland Walker on 4/10/26.
//

import Foundation
import KlipyCore

protocol KlipyTrayLoading: Sendable {
    var configuration: KlipyConfiguration { get }

    func categories(
        kind: KlipyMediaType,
        locale: String?
    ) async throws -> [KlipyCategory]

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

extension KlipyClient: KlipyTrayLoading {}
