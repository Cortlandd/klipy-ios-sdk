//
//  KlipyPage.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation
import CoreGraphics

public struct KlipyPageMeta: Decodable, Sendable, Equatable {
    public let itemMinWidth: CGFloat?
    public let adMaxResizePercent: CGFloat?

    private enum CodingKeys: String, CodingKey {
        case itemMinWidth = "item_min_width"
        case adMaxResizePercent = "ad_max_resize_percent"
    }

    public init(
        itemMinWidth: CGFloat? = nil,
        adMaxResizePercent: CGFloat? = nil
    ) {
        self.itemMinWidth = itemMinWidth
        self.adMaxResizePercent = adMaxResizePercent
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        itemMinWidth = Self.decodeCGFloatIfPresent(from: container, forKey: .itemMinWidth)
        adMaxResizePercent = Self.decodeCGFloatIfPresent(from: container, forKey: .adMaxResizePercent)
    }

    private static func decodeCGFloatIfPresent(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> CGFloat? {
        if let value = try? container.decodeIfPresent(CGFloat.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return CGFloat(value)
        }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return CGFloat(value)
        }
        if let value = try? container.decodeIfPresent(String.self, forKey: key),
           let doubleValue = Double(value) {
            return CGFloat(doubleValue)
        }
        return nil
    }
}

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
    public let meta: KlipyPageMeta?

    private enum CodingKeys: String, CodingKey {
        case data          = "data"
        case currentPage   = "current_page"
        case perPage       = "per_page"
        case hasNext       = "has_next"
        case meta
    }

    /// Public memberwise initializer so other modules (e.g., KlipyTray) can construct pages.
    public init(
        data: [Item],
        currentPage: Int,
        perPage: Int,
        hasNext: Bool,
        meta: KlipyPageMeta? = nil
    ) {
        self.data = data
        self.currentPage = currentPage
        self.perPage = perPage
        self.hasNext = hasNext
        self.meta = meta
    }
}
