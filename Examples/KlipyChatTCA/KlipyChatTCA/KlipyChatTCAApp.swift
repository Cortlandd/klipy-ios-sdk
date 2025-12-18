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
                        apiKey: "wx4NS4jKDijkRGIrNvsuSRAzCm2ZQYVfBIHUU951ZPOHRBDD8OQkoNqjO16UgW1W"
                    )
                ) {
                    ChatFeature()
                }
            )
        }
    }
}
