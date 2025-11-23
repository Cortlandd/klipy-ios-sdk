//
//  KlipyClient+Sticker.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation

public extension KlipyClient {

    func searchStickers(
        query: String,
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil,
        customerId: String? = nil
    ) async throws -> KlipyPage<KlipyMedia> {
        try await search(
            kind: .sticker,
            query: query,
            page: page,
            perPage: perPage,
            locale: locale,
            customerId: customerId
        )
    }

    func trendingStickers(
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil,
        customerId: String
    ) async throws -> KlipyPage<KlipyMedia> {
        try await trending(
            kind: .sticker,
            page: page,
            perPage: perPage,
            locale: locale,
            customerId: customerId
        )
    }

    func sticker(slug: String) async throws -> KlipyMedia {
        try await item(kind: .sticker, slugOrId: slug)
    }

    func stickerCategories(locale: String? = nil) async throws -> [KlipyCategory] {
        try await categories(kind: .sticker, locale: locale)
    }
}
