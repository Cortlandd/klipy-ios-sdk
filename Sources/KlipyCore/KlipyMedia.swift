//
//  KlipyMedia.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation

/// Type of media returned by the Klipy API.
/// The exact set may grow as Klipy adds products.
public enum KlipyMediaType: String, Codable, Sendable {
    case gif
    case sticker
    case clip
    case meme

    /// Path segment used in URLs, e.g. "gifs", "stickers"
    var pathSegment: String {
        switch self {
        case .gif:     return "gifs"
        case .sticker: return "stickers"
        case .clip:    return "clips"
        case .meme:    return "static-memes"
        }
    }
}

/// Individual rendition of a media item (legacy helper).
/// You can still use this if you want to normalize
/// a chosen variant into a simpler shape.
public struct KlipyMediaRendition: Codable, Sendable {
    public let url: URL
    public let width: Int?
    public let height: Int?
    public let sizeBytes: Int?
    public let mimeType: String?

    public init(
        url: URL,
        width: Int? = nil,
        height: Int? = nil,
        sizeBytes: Int? = nil,
        mimeType: String? = nil
    ) {
        self.url = url
        self.width = width
        self.height = height
        self.sizeBytes = sizeBytes
        self.mimeType = mimeType
    }
}

// MARK: - Nested file structure

/// Lowest-level asset in the `file` tree.
///
/// Example:
/// "gif": {
///   "url": "https://static.klipy.com/...",
///   "width": 498,
///   "height": 498,
///   "size": 4001918
/// }
public struct KlipyMediaFileAsset: Codable, Sendable {
    public let url: URL
    public let width: Int?
    public let height: Int?
    public let sizeBytes: Int?

    private enum CodingKeys: String, CodingKey {
        case url
        case width
        case height
        case sizeBytes = "size"
    }
}

/// A resolution bucket inside `file` (hd, md, sm, xs),
/// containing multiple formats (gif, webp, jpg, mp4, webm).
public struct KlipyMediaFileBucket: Codable, Sendable {
    public let gif: KlipyMediaFileAsset?
    public let webp: KlipyMediaFileAsset?
    public let jpg: KlipyMediaFileAsset?
    public let mp4: KlipyMediaFileAsset?
    public let webm: KlipyMediaFileAsset?
}

/// Full `file` object as returned by the Klipy API.
///
/// Example:
/// "file": {
///   "hd": { "gif": { ... }, "webp": { ... }, ... },
///   "md": { ... },
///   "sm": { ... },
///   "xs": { ... }
/// }
public struct KlipyMediaFile: Codable, Sendable {
    public let hd: KlipyMediaFileBucket?
    public let md: KlipyMediaFileBucket?
    public let sm: KlipyMediaFileBucket?
    public let xs: KlipyMediaFileBucket?
}

// MARK: - Public media model

/// KLIPY media item (GIF, Sticker, Clip, Meme).
/// Shape is designed to be stable across products.
public struct KlipyMedia: Codable, Identifiable, Sendable {
    /// Unique identifier for the item. Handling separately if its an Int
    public let id: String

    /// Human readable slug/short id if available.
    public let slug: String

    public let type: KlipyMediaType

    public let title: String?

    /// Raw `file` tree with all variants (hd/md/sm/xs × gif/webp/jpg/mp4/webm).
    public let file: KlipyMediaFile?

    /// Base64 blur preview (if present).
    public let blurPreview: String?

    /// Primary preview image (low-res static or animated).
    /// Derived from `file` (prefers `sm.gif` → `xs.gif` → `sm.webp` → `xs.webp` → `sm.jpg`).
    public let previewURL: URL?

    /// Main GIF URL (for GIF-type items).
    /// Derived from `file` (prefers `md.gif` → `hd.gif` → `sm.gif` → `xs.gif`).
    public let gifURL: URL?

    /// Optional MP4 URL (for clips or optimized playback).
    /// Derived from `file` (prefers `md.mp4` → `hd.mp4` → `sm.mp4` → `xs.mp4`).
    public let mp4URL: URL?

    /// Optional WebP URL for supported platforms.
    /// Derived from `file` (prefers `md.webp` → `hd.webp` → `sm.webp` → `xs.webp`).
    public let webpURL: URL?

    /// Chosen width/height for the primary playback asset.
    /// Prefers the GIF dimensions; falls back to preview.
    public let width: Int?
    public let height: Int?

    /// Tag list provided by the API.
    public let tags: [String]?

    // MARK: - Coding

    private enum CodingKeys: String, CodingKey {
        case id
        case slug
        case type
        case title
        case file
        case tags
        case blurPreview = "blur_preview"
    }

    public init(
        id: String,
        slug: String,
        type: KlipyMediaType,
        title: String?,
        file: KlipyMediaFile?,
        blurPreview: String?,
        previewURL: URL?,
        gifURL: URL?,
        mp4URL: URL?,
        webpURL: URL?,
        width: Int?,
        height: Int?,
        tags: [String]?
    ) {
        self.id = id
        self.slug = slug
        self.type = type
        self.title = title
        self.file = file
        self.blurPreview = blurPreview
        self.previewURL = previewURL
        self.gifURL = gifURL
        self.mp4URL = mp4URL
        self.webpURL = webpURL
        self.width = width
        self.height = height
        self.tags = tags
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // id can be String or Int – normalize to String
        if let idString = try? c.decode(String.self, forKey: .id) {
            self.id = idString
        } else if let idInt = try? c.decode(Int.self, forKey: .id) {
            self.id = String(idInt)
        } else if let slug = try? c.decode(String.self, forKey: .slug) {
            // some endpoints might not send `id` but do send `slug`
            self.id = slug
        } else {
            // last resort to avoid decode failure
            self.id = UUID().uuidString
        }

        self.slug = try c.decode(String.self, forKey: .slug)
        self.type = (try? c.decode(KlipyMediaType.self, forKey: .type)) ?? .gif
        self.title = try? c.decode(String.self, forKey: .title)
        self.tags = try? c.decode([String].self, forKey: .tags)
        self.blurPreview = try? c.decode(String.self, forKey: .blurPreview)
        self.file = try? c.decode(KlipyMediaFile.self, forKey: .file)

        // Derive URLs + dimensions from the file tree
        let derivedPreview = KlipyMedia.pickPreview(from: file)
        let derivedGif = KlipyMedia.pickGif(from: file)
        let derivedMp4 = KlipyMedia.pickMp4(from: file)
        let derivedWebp = KlipyMedia.pickWebp(from: file)

        self.previewURL = derivedPreview.url
        self.gifURL = derivedGif.url
        self.mp4URL = derivedMp4?.url
        self.webpURL = derivedWebp?.url

        // Prefer GIF dimensions, then preview
        self.width = derivedGif.width ?? derivedPreview.width
        self.height = derivedGif.height ?? derivedPreview.height
    }

    // MARK: - Selection helpers

    /// Choose the best preview asset (small GIF/WebP/JPG) for grid/list.
    private static func pickPreview(from file: KlipyMediaFile?) -> (url: URL?, width: Int?, height: Int?) {
        guard let file = file else { return (nil, nil, nil) }

        // preference: small gif → extra-small gif → small webp → extra-small webp → small jpg
        let candidates: [KlipyMediaFileAsset?] = [
            file.sm?.gif,
            file.xs?.gif,
            file.sm?.webp,
            file.xs?.webp,
            file.sm?.jpg
        ]

        if let asset = candidates.compactMap({ $0 }).first {
            return (asset.url, asset.width, asset.height)
        }

        return (nil, nil, nil)
    }

    /// Choose the main GIF asset used for playback.
    private static func pickGif(from file: KlipyMediaFile?) -> (url: URL?, width: Int?, height: Int?) {
        guard let file = file else { return (nil, nil, nil) }

        // preference: medium → hd → small → xs
        let candidates: [KlipyMediaFileAsset?] = [
            file.md?.gif,
            file.hd?.gif,
            file.sm?.gif,
            file.xs?.gif
        ]

        if let asset = candidates.compactMap({ $0 }).first {
            return (asset.url, asset.width, asset.height)
        }

        return (nil, nil, nil)
    }

    /// Choose the best MP4 asset, if present.
    private static func pickMp4(from file: KlipyMediaFile?) -> KlipyMediaFileAsset? {
        guard let file = file else { return nil }

        let candidates: [KlipyMediaFileAsset?] = [
            file.md?.mp4,
            file.hd?.mp4,
            file.sm?.mp4,
            file.xs?.mp4
        ]

        return candidates.compactMap { $0 }.first
    }

    /// Choose the best WebP asset, if present.
    private static func pickWebp(from file: KlipyMediaFile?) -> KlipyMediaFileAsset? {
        guard let file = file else { return nil }

        let candidates: [KlipyMediaFileAsset?] = [
            file.md?.webp,
            file.hd?.webp,
            file.sm?.webp,
            file.xs?.webp
        ]

        return candidates.compactMap { $0 }.first
    }
}

public struct KlipyMediaListPayload: Decodable, Sendable {
    public let data: [KlipyMedia]
}
