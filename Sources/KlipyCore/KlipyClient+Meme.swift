//
//  KlipyClient+Meme.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation

public extension KlipyClient {

    func searchMemes(
        query: String,
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil,
    ) async throws -> KlipyPage<KlipyMedia> {
        try await search(
            kind: .meme,
            query: query,
            page: page,
            perPage: perPage,
            locale: locale,
        )
    }

    func trendingMemes(
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil,
    ) async throws -> KlipyPage<KlipyMedia> {
        try await trending(
            kind: .meme,
            page: page,
            perPage: perPage,
            locale: locale,
        )
    }

    func meme(slug: String) async throws -> KlipyMedia {
        try await item(kind: .meme, slugOrId: slug)
    }

    func memeCategories(locale: String? = nil) async throws -> [KlipyCategory] {
        try await categories(kind: .meme, locale: locale)
    }
}
