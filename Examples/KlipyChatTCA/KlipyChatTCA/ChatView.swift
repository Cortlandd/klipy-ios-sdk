//
//  ChatView.swift
//  KlipyChatTCA
//
//  Created by Cortland Walker on 12/17/25.
//


import SwiftUI
import ComposableArchitecture
import KlipyCore
import KlipyTray

public struct ChatView: View {
    @Bindable public var store: StoreOf<ChatFeature>

    public init(store: StoreOf<ChatFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            messagesList

            Divider()

            composer
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
        }
        .navigationTitle("Klipy Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.send(.onAppear) }
        .sheet(isPresented: $store.isTrayPresented) {
            // Create the client once per sheet open; if you want a single instance,
            // create it in State or a Dependency. For demo this is fine.
            let client = KlipyClient(configuration: .init(apiKey: store.apiKey))

            KlipyTrayView(
                client: client,
                config: store.trayConfig,
                onSelect: { media in
                    store.send(.trayMediaSelected(media))
                },
                onError: { _ in }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(0)
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(store.messages) { message in
                        MessageRow(message: message)
                            .id(message.id)
                            .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .onChange(of: store.messages.count) { _ in
                guard let last = store.messages.last else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            Button {
                store.send(.plusTapped)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
            }
            .buttonStyle(.plain)

            TextField("iMessage", text: $store.draftText)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

            Button {
                store.send(.sendTapped)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled(store.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(store.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
        }
    }
}
