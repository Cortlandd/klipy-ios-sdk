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
                    .disabled(!isAPIKeyConfigured)
                    .opacity(isAPIKeyConfigured ? 1.0 : 0.4)

                    if !isAPIKeyConfigured {
                        Text("Set KLIPY_API_KEY in the scheme environment or the app's KLIPY_API_KEY Info.plist value before opening the picker.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
                .padding()
                .navigationTitle("Klipy TCA Demo")
                .sheet(item: $store.scope(state: \.destination, action: \.destination)) { destStore in
                    switch destStore.case {
                    case let .picker(pickerStore):
                        if let client {
                            KlipyPickerSheet(store: pickerStore, client: client)
                                .ignoresSafeArea(edges: .bottom)
                        }
                    }
                }
            }
        }
    }

    private var client: KlipyClient? {
        guard isAPIKeyConfigured else {
            return nil
        }

        return KlipyClient(configuration: .init(apiKey: KlipySampleTCAConfig.apiKey))
    }

    private var isAPIKeyConfigured: Bool {
        !KlipySampleTCAConfig.apiKey.isEmpty
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

private enum KlipySampleTCAConfig {
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
