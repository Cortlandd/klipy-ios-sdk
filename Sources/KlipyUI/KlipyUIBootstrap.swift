//
//  KlipyUIBootstrap.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/25/25.
//

import Foundation
import SDWebImage
import SDWebImageWebPCoder

public enum KlipyUIBootstrap {
    private final class State: @unchecked Sendable {
        let lock = NSLock()
        var isConfigured = false
    }

    private static let state = State()

    public static func configureIfNeeded() {
        state.lock.lock()
        defer { state.lock.unlock() }

        guard !state.isConfigured else { return }
        state.isConfigured = true

        let webpCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(webpCoder)
    }
}
