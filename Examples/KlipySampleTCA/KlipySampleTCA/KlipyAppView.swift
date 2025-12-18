//
//  KlipyAppView.swift
//  KlipySampleTCA
//
//  Created by Cortland Walker on 11/24/25.
//

import SwiftUI
import ComposableArchitecture
import KlipyCore
import KlipyUI

struct KlipyAppView: View {
    @Bindable var store: StoreOf<KlipyAppFeature>

    private let client = KlipyClient(
        configuration: KlipyConfiguration(apiKey: "wx4NS4jKDijkRGIrNvsuSRAzCm2ZQYVfBIHUU951ZPOHRBDD8OQkoNqjO16UgW1W")
    )

    var body: some View {
        NavigationView {
            WithPerceptionTracking {
                VStack(spacing: 24) {
                    selectedMediaSection

                    Button {
                        store.send(.openPickerButtonTapped)
                    } label: {
                        Text("Open Klipy Picker")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Spacer()
                }
                .padding()
                .navigationTitle("Klipy TCA Demo")
                .sheet(item: $store.scope(state: \.destination, action: \.destination)) { destStore in
                    switch destStore.case {
                    case let .picker(pickerStore):
                        KlipyPickerSheet(store: pickerStore, client: client)
                            .ignoresSafeArea(edges: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var selectedMediaSection: some View {
        WithPerceptionTracking {
            if let media = store.selectedMedia {
                VStack(spacing: 12) {
                    Text("Selected media")
                        .font(.headline)

                    KlipyMediaPreviewView(media: media)
                        .frame(height: 220)

                    Text(media.title ?? media.slug)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            } else {
                VStack(spacing: 8) {
                    Text("No media selected yet")
                        .font(.headline)
                    Text("Tap the button below to open Klipy and pick something.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}
