//
//  KlipyCategory.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation

public struct KlipyCategory: Codable, Identifiable, Sendable, Equatable {
    /// Derive `id` from the query string for Identifiable.
    public var id: String { query }

    public let category: String
    public let query: String
    public let previewURL: String

    private enum CodingKeys: String, CodingKey {
        case category
        case query
        case previewURL = "preview_url"
    }
}

/// Raw payload returned in `data` for the Categories API.
/// Shape:
/// {
///   "locale": "en_US",
///   "categories": [ { ...KlipyCategory... } ]
/// }
public struct KlipyCategoryPayload: Decodable, Equatable, Sendable {
    public let locale: String
    public let categories: [KlipyCategory]
}

public struct KlipySearchSuggestion: Codable, Identifiable, Sendable {
    public let id: String
    public let text: String

    private enum CodingKeys: String, CodingKey {
        case id
        case text
        case query
        case value
    }

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }

    public init(from decoder: Decoder) throws {
        // Try a simple string array: ["cat", "car", ...]
        if let single = try? decoder.singleValueContainer().decode(String.self) {
            self.text = single
            self.id = single
            return
        }

        let c = try decoder.container(keyedBy: CodingKeys.self)

        // Try to infer text from several possible keys
        let text =
            (try? c.decode(String.self, forKey: .text)) ??
            (try? c.decode(String.self, forKey: .query)) ??
            (try? c.decode(String.self, forKey: .value)) ??
            ""

        // Prefer explicit id, or fall back to text
        let id = (try? c.decode(String.self, forKey: .id)) ?? text

        self.id = id
        self.text = text
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(text, forKey: .text)
    }
}
