//
//  KlipyClient+Emoji.swift
//  KlipySDK
//
//  Created by Cortland Walker on 4/11/26.
//

import Foundation

public extension KlipyClient {

    func searchEmojis(
        query: String,
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil
    ) async throws -> KlipyPage<KlipyMedia> {
        try await search(
            kind: .emoji,
            query: query,
            page: page,
            perPage: perPage,
            locale: locale
        )
    }

    func trendingEmojis(
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil
    ) async throws -> KlipyPage<KlipyMedia> {
        try await trending(
            kind: .emoji,
            page: page,
            perPage: perPage,
            locale: locale
        )
    }

    func emoji(slug: String) async throws -> KlipyMedia {
        try await item(kind: .emoji, slugOrId: slug)
    }

    func emojiCategories(locale: String? = nil) async throws -> [KlipyCategory] {
        try await categories(kind: .emoji, locale: locale)
    }
}
