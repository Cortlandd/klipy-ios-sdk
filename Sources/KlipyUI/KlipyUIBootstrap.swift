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
    public static func configureIfNeeded() {
        // Only register once
//        struct Token { static var configured = false }
//        guard !Token.configured else { return }
//        Token.configured = true

        let webpCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(webpCoder)
    }
}
