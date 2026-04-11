//
//  KlipyApp.swift
//  KlipyChatTCA
//
//  Created by Cortland Walker on 12/17/25.
//

import SwiftUI
import ComposableArchitecture
import KlipyCore

@main
struct KlipyChatTCAApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView(
                store: Store(
                    initialState: ChatFeature.State(
                        apiKey: KlipyChatTCAConfig.apiKey
                    )
                ) {
                    ChatFeature()
                }
            )
        }
    }
}

private enum KlipyChatTCAConfig {
    static let apiKey: String = {
        if let environmentValue = ProcessInfo.processInfo.environment["KLIPY_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !environmentValue.isEmpty {
            return environmentValue
        }

        if let infoValue = Bundle.main.object(forInfoDictionaryKey: "KLIPY_API_KEY") as? String {
            let trimmed = infoValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return ""
    }()
}
