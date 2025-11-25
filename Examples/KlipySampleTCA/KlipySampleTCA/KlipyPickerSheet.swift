//
//  KlipyPickerSheet.swift
//  KlipySampleTCA
//
//  Created by Cortland Walker on 11/24/25.
//

import SwiftUI
import ComposableArchitecture
import KlipyCore
import KlipyUI

struct KlipyPickerSheet: View {
    let store: StoreOf<KlipyPickerFeature>
    let client: KlipyClient

    var body: some View {
        WithPerceptionTracking {
            KlipyPickerView(
                client: client,
                initialTab: .gifs,
                onSelect: { media in
                    store.send(.mediaSelected(media))
                },
                onClose: {
                    store.send(.closeTapped)
                }
            )
        }
    }
}
