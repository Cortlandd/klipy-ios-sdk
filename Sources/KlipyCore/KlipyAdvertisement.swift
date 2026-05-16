//
//  KlipyAdvertisement.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import Foundation

/// Advertisement object returned alongside normal Klipy media content.
public struct KlipyAdvertisement: Codable, Identifiable, Sendable, Equatable {
    public let content: String
    public let width: Int?
    public let height: Int?
    public let type: String

    public init(
        content: String,
        width: Int? = nil,
        height: Int? = nil,
        type: String = "ad"
    ) {
        self.content = content
        self.width = width
        self.height = height
        self.type = type
    }
}

public extension KlipyAdvertisement {
    var id: String {
        content
    }

    var contentURL: URL? {
        URL(string: content)
    }
}

/// Mixed content item returned by Klipy feeds, which may contain either media or ads.
public enum KlipyContentItem: Decodable, Identifiable, Sendable, Equatable {
    case media(KlipyMedia)
    case advertisement(KlipyAdvertisement)

    public var id: String {
        switch self {
        case .media(let media):
            return media.id
        case .advertisement(let ad):
            return ad.id
        }
    }

    public var media: KlipyMedia? {
        guard case .media(let media) = self else { return nil }
        return media
    }

    public var advertisement: KlipyAdvertisement? {
        guard case .advertisement(let ad) = self else { return nil }
        return ad
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type)?.lowercased()

        if type == "ad" {
            self = .advertisement(try KlipyAdvertisement(from: decoder))
        } else {
            self = .media(try KlipyMedia(from: decoder))
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }
}

public extension KlipyPage where Item == KlipyContentItem {
    var mediaOnly: [KlipyMedia] {
        data.compactMap(\.media)
    }

    var advertisementsOnly: [KlipyAdvertisement] {
        data.compactMap(\.advertisement)
    }

    var mediaPage: KlipyPage<KlipyMedia> {
        KlipyPage<KlipyMedia>(
            data: mediaOnly,
            currentPage: currentPage,
            perPage: perPage,
            hasNext: hasNext,
            meta: meta
        )
    }
}
