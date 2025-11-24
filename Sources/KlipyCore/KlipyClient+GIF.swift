//
//  KlipyClient+GIF.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation

public extension KlipyClient {

    /// Convenience wrapper for searching GIFs.
    func searchGIFs(
        query: String,
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil
    ) async throws -> KlipyPage<KlipyMedia> {
        try await search(
            kind: .gif,
            query: query,
            page: page,
            perPage: perPage,
            locale: locale,
        )
    }

    /// Convenience wrapper for trending GIFs.
    func trendingGIFs(
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil
    ) async throws -> KlipyPage<KlipyMedia> {
        try await trending(
            kind: .gif,
            page: page,
            perPage: perPage,
            locale: locale
        )
    }

    /// Convenience wrapper for a single GIF by slug/ID.
    func gif(slug: String) async throws -> KlipyMedia {
        try await item(kind: .gif, slugOrId: slug)
    }

    /// Categories specific to GIFs.
    func gifCategories(locale: String? = nil) async throws -> [KlipyCategory] {
        try await categories(kind: .gif, locale: locale)
    }
}
