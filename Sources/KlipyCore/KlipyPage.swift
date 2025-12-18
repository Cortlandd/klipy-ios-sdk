//
//  KlipyPage.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation

/// A generic paginated container used for the Klipy API.
///
/// Klipy uses a consistent paging structure across many endpoints,
/// but the type of the items inside the page varies depending on the endpoint.
/// Therefore, `Item` is a generic placeholder that represents the decoded
/// element type for that specific API call.
///
/// For example:
/// - GIF search → `KlipyPage<KlipyMedia>`
/// - Sticker trending → `KlipyPage<KlipyMedia>`
/// - Meme search → `KlipyPage<KlipyMedia>`
/// - Suggestions or autocomplete → `KlipyPage<String>`
/// - Future endpoints may return categories, ads, or other models.
///
/// JSON structure this maps to:
/// {
///   "data": [ ... ], // Array of `Item`
///   "current_page": 1,
///   "per_page": 24,
///   "has_next": true
/// }
///
/// The SDK binds `Item` at the call site, ensuring every endpoint returns
/// a strongly typed, predictable payload.
public struct KlipyPage<Item: Decodable & Sendable>: Decodable, Sendable {
    /// The actual payload array from the API.
    public let data: [Item]

    public let currentPage: Int
    public let perPage: Int
    public let hasNext: Bool

    private enum CodingKeys: String, CodingKey {
        case data          = "data"
        case currentPage   = "current_page"
        case perPage       = "per_page"
        case hasNext       = "has_next"
    }

    /// Public memberwise initializer so other modules (e.g., KlipyTray) can construct pages.
    public init(data: [Item], currentPage: Int, perPage: Int, hasNext: Bool) {
        self.data = data
        self.currentPage = currentPage
        self.perPage = perPage
        self.hasNext = hasNext
    }
}
