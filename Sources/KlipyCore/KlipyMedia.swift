//
//  KlipyMedia.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation
import CoreGraphics

// MARK: - Media Type

/// Type of media returned by the Klipy API.
public enum KlipyMediaType: String, Codable, Sendable, Equatable {
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

// MARK: - Nested file structure

/// Lowest-level asset in the `file` tree for GIF/meme/sticker.
///
/// Example:
/// "gif": {
///   "url": "https://static.klipy.com/",
///   "width": 498,
///   "height": 498,
///   "size": 4001918
/// }
public struct KlipyMediaFileAsset: Codable, Sendable, Equatable {
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
public struct KlipyMediaFileBucket: Codable, Sendable, Equatable {
    public let gif: KlipyMediaFileAsset?
    public let webp: KlipyMediaFileAsset?
    public let jpg: KlipyMediaFileAsset?
    public let mp4: KlipyMediaFileAsset?
    public let webm: KlipyMediaFileAsset?
}

/// Full `file` object as returned by the Klipy API.
///
/// GIF/meme/sticker:
/// "file": {
///   "hd": { "gif": { ... }, "webp": { ... }, ... },
///   "md": { ... },
///   "sm": { ... },
///   "xs": { ... }
/// }
///
/// Clip responses:
/// "file": {
///   "mp4": "https://...",
///   "gif": "https://.../something.gif",
///   "webp": "https://.../something.webp"
/// }
public struct KlipyMediaFile: Codable, Sendable, Equatable {
    // GIF-style buckets
    public let hd: KlipyMediaFileBucket?
    public let md: KlipyMediaFileBucket?
    public let sm: KlipyMediaFileBucket?
    public let xs: KlipyMediaFileBucket?

    // Clip-style flat fields (strings → URLs)
    public let mp4: URL?
    public let gif: URL?
    public let webp: URL?
}

/// Metadata for clip `file_meta`.
public struct KlipyMediaFileMeta: Codable, Sendable, Equatable {
    public let mp4: KlipyMediaFileMetaEntry?
    public let gif: KlipyMediaFileMetaEntry?
    public let webp: KlipyMediaFileMetaEntry?
}

public struct KlipyMediaFileMetaEntry: Codable, Sendable, Equatable {
    public let width: Int?
    public let height: Int?
}

// MARK: - Public media model

/// KLIPY media item (GIF, Sticker, Clip, Meme).
public struct KlipyMedia: Codable, Identifiable, Sendable, Equatable {
    /// Unique identifier for the item.
    /// The API sometimes sends `id` as an Int or String; we normalize to String.
    public let id: String

    /// Human readable slug/short id.
    public let slug: String

    public let type: KlipyMediaType
    public let title: String?

    /// Raw `file` tree with all variants.
    public let file: KlipyMediaFile?
    public let fileMeta: KlipyMediaFileMeta?

    /// Base64 blur preview (`data:image/jpeg;base64,...`).
    public let blurPreview: String?

    /// Tag list provided by the API.
    public let tags: [String]?

    private enum CodingKeys: String, CodingKey {
        case id
        case slug
        case type
        case title
        case file
        case fileMeta = "file_meta"
        case blurPreview = "blur_preview"
        case tags
    }

    // Minimal custom decoding JUST to normalize id (Int or String).
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

        self.slug        = (try? c.decode(String.self, forKey: .slug)) ?? self.id
        self.type        = (try? c.decode(KlipyMediaType.self, forKey: .type)) ?? .gif
        self.title       = try? c.decode(String.self, forKey: .title)
        self.file        = try? c.decode(KlipyMediaFile.self, forKey: .file)
        self.fileMeta    = try? c.decode(KlipyMediaFileMeta.self, forKey: .fileMeta)
        self.blurPreview = try? c.decode(String.self, forKey: .blurPreview)
        self.tags        = try? c.decode([String].self, forKey: .tags)
    }

    // Explicit memberwise init so you can construct in tests if needed.
    public init(
        id: String,
        slug: String,
        type: KlipyMediaType,
        title: String? = nil,
        file: KlipyMediaFile? = nil,
        fileMeta: KlipyMediaFileMeta? = nil,
        blurPreview: String? = nil,
        tags: [String]? = nil
    ) {
        self.id = id
        self.slug = slug
        self.type = type
        self.title = title
        self.file = file
        self.fileMeta = fileMeta
        self.blurPreview = blurPreview
        self.tags = tags
    }
}

// Simple wrapper for endpoints that return `{ "data": [ ... ] }`
public struct KlipyMediaListPayload: Decodable, Sendable, Equatable {
    public let data: [KlipyMedia]
}

// MARK: - URL selection helpers

public extension KlipyMedia {
    /// Aspect ratio used for grid tiles.
    ///
    /// - For most types we use `file_meta.webp` as-is.
    /// - For clips we clamp to a reasonable range so extremely wide/short clips
    ///   don't break the grid layout.
    var aspectRatio: CGFloat {
        let base: CGFloat

        if let w = fileMeta?.webp?.width,
           let h = fileMeta?.webp?.height,
           h > 0 {
            base = CGFloat(w) / CGFloat(h)
        } else {
            base = 1.0
        }

        // Clips can be *very* wide vs tall. Clamp so layout stays sane.
        if type == .clip {
            // e.g. between ~3:4 (taller) and ~16:9 (wider)
            return max(0.75, min(base, 1.9))
        } else {
            // Other media still get a bit of clamping just in case.
            return max(0.6, min(base, 1.9))
        }
    }

    /// Best still image to show in grids / previews.
    ///
    /// - First try bucketed assets (sm/xs webp/gif/jpg).
    /// - If that fails and this is a clip, fall back to flat `file.webp/gif/mp4`.
    /// - Does **not** use `blurPreview` as a URL.
    var previewURL: URL? {
        // 1. Normal bucketed assets
        if let url =
            file?.sm?.webp?.url ??
            file?.sm?.gif?.url ??
            file?.sm?.jpg?.url ??
            file?.xs?.webp?.url ??
            file?.xs?.gif?.url ??
            file?.xs?.jpg?.url {
            return url
        }

        // 2. Clip flat shape
        if type == .clip {
            if let webp = file?.webp { return webp }
            if let gif  = file?.gif  { return gif }
            if let mp4  = file?.mp4  { return mp4 }
        }

        return nil
    }

    var gifURL: URL? {
        file?.gif
            ?? file?.sm?.gif?.url
            ?? file?.md?.gif?.url
            ?? file?.xs?.gif?.url
    }

    var mp4URL: URL? {
        file?.mp4
            ?? file?.sm?.mp4?.url
            ?? file?.md?.mp4?.url
            ?? file?.xs?.mp4?.url
    }

    var webpURL: URL? {
        file?.webp
            ?? file?.sm?.webp?.url
            ?? file?.md?.webp?.url
            ?? file?.xs?.webp?.url
    }
    
    var displayAspectRatio: CGFloat {
        if type == .clip {
            return 16.0 / 9.0
        }
        return aspectRatio   // your existing helper that uses fileMeta.webp
    }
}
