//
//  KlipyApp.swift
//  KlipySampleTCA
//
//  Created by Cortland Walker on 11/24/25.
//

import SwiftUI
import ComposableArchitecture

@main
struct KlipyApp: App {

    var body: some Scene {
        WindowGroup {
            KlipyAppView(
                store: Store(
                    initialState: KlipyAppFeature.State(),
                    reducer: { KlipyAppFeature() }
                )
            )
        }
    }
}
