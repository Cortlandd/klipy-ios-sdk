//
//  KlipyPickerMediaTab.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/24/25.
//

import Foundation
import KlipyCore

public enum KlipyPickerMediaTab: String, CaseIterable, Equatable, Sendable {
    case gifs
    case stickers
    case clips
    case memes
    case emojis

    public var title: String {
        switch self {
        case .gifs:     return "GIFs"
        case .stickers: return "Stickers"
        case .clips:    return "Clips"
        case .memes:    return "Memes"
        case .emojis:   return "Emojis"
        }
    }

    public var mediaType: KlipyMediaType {
        switch self {
        case .gifs:     return .gif
        case .stickers: return .sticker
        case .clips:    return .clip
        case .memes:    return .meme
        case .emojis:   return .emoji
        }
    }
}
