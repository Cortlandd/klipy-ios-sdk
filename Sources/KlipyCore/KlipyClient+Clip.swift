//
//  KlipyClient+Clip.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation

public extension KlipyClient {

    func searchClips(
        query: String,
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil,
        customerId: String? = nil
    ) async throws -> KlipyPage<KlipyMedia> {
        try await search(
            kind: .clip,
            query: query,
            page: page,
            perPage: perPage,
            locale: locale,
            customerId: customerId
        )
    }

    func trendingClips(
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil,
        customerId: String
    ) async throws -> KlipyPage<KlipyMedia> {
        try await trending(
            kind: .clip,
            page: page,
            perPage: perPage,
            locale: locale,
            customerId: customerId
        )
    }

    func clip(slug: String) async throws -> KlipyMedia {
        try await item(kind: .clip, slugOrId: slug)
    }

    func clipCategories(locale: String? = nil) async throws -> [KlipyCategory] {
        try await categories(kind: .clip, locale: locale)
    }
}
