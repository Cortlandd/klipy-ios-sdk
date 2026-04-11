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
                config: KlipyPickerConfig(
                    mediaTabs: [.gifs, .stickers, .clips, .memes, .emojis],
                    columns: 3,
                    showRecents: false,
                    showTrending: true,
                    initialTab: .gifs
                ),
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
