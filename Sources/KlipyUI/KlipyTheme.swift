//
//  KlipyTheme.swift
//  KlipySDK
//
//  Created by Codex on 5/16/26.
//

import SwiftUI

/// Presentation mode for the app-facing Klipy UI surfaces.
public enum KlipyThemeMode: String, CaseIterable, Codable, Equatable, Sendable {
    case automatic
    case light
    case dark
    case lightBlur
    case darkBlur
}

/// Theme configuration for the picker and tray surfaces.
public struct KlipyTheme: Codable, Equatable, Sendable {
    public var mode: KlipyThemeMode

    public init(mode: KlipyThemeMode = .automatic) {
        self.mode = mode
    }

    public static let automatic = KlipyTheme(mode: .automatic)
    public static let light = KlipyTheme(mode: .light)
    public static let dark = KlipyTheme(mode: .dark)
    public static let lightBlur = KlipyTheme(mode: .lightBlur)
    public static let darkBlur = KlipyTheme(mode: .darkBlur)
}

public struct KlipyThemePalette {
    public let mode: KlipyThemeMode
    public let background: Color
    public let surface: Color
    public let secondarySurface: Color
    public let primaryText: Color
    public let secondaryText: Color
    public let separator: Color
    public let chromeMaterial: Material?
}

extension KlipyTheme {
    public func resolvedMode(for colorScheme: ColorScheme) -> KlipyThemeMode {
        switch mode {
        case .automatic:
            return colorScheme == .dark ? .dark : .light
        case .light, .dark, .lightBlur, .darkBlur:
            return mode
        }
    }

    public func palette(for colorScheme: ColorScheme) -> KlipyThemePalette {
        switch resolvedMode(for: colorScheme) {
        case .automatic, .light:
            return KlipyThemePalette(
                mode: .light,
                background: Color.white,
                surface: Color(.systemBackground),
                secondarySurface: Color(.systemGray6),
                primaryText: .primary,
                secondaryText: .secondary,
                separator: Color(.separator),
                chromeMaterial: nil
            )
        case .dark:
            return KlipyThemePalette(
                mode: .dark,
                background: Color(.systemGray6),
                surface: Color(.secondarySystemBackground),
                secondarySurface: Color(.tertiarySystemBackground),
                primaryText: .white,
                secondaryText: Color.white.opacity(0.7),
                separator: Color.white.opacity(0.14),
                chromeMaterial: nil
            )
        case .lightBlur:
            return KlipyThemePalette(
                mode: .lightBlur,
                background: Color.white.opacity(0.65),
                surface: Color.white.opacity(0.72),
                secondarySurface: Color.white.opacity(0.78),
                primaryText: .primary,
                secondaryText: .secondary,
                separator: Color.black.opacity(0.08),
                chromeMaterial: .regularMaterial
            )
        case .darkBlur:
            return KlipyThemePalette(
                mode: .darkBlur,
                background: Color.black.opacity(0.5),
                surface: Color.black.opacity(0.35),
                secondarySurface: Color.white.opacity(0.1),
                primaryText: .white,
                secondaryText: Color.white.opacity(0.74),
                separator: Color.white.opacity(0.12),
                chromeMaterial: .ultraThinMaterial
            )
        }
    }
}
