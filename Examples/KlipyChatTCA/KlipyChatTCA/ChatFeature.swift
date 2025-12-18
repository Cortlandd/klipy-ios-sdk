//
//  ChatFeature.swift
//  KlipyChatTCA
//
//  Created by Cortland Walker on 12/17/25.
//

import Foundation
import ComposableArchitecture
import KlipyCore
import KlipyUI
import KlipyTray

@Reducer
public struct ChatFeature {

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var apiKey: String

        public var messages: [ChatMessage] = []
        public var draftText: String = ""
        public var isTrayPresented: Bool = false

        public var trayConfig: KlipyTrayConfig = .init(
            mediaTabs: [.gifs, .stickers, .clips, .memes],
            initialTab: .gifs,
            columns: 3,
            showTrending: true,
            showRecents: false,
            showCategories: true,
            showSearch: true
        )

        public init(apiKey: String) {
            self.apiKey = apiKey
            self.messages = ChatSeed.sampleConversation
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)

        case onAppear
        case plusTapped
        case trayDismissed

        case sendTapped
        case trayMediaSelected(KlipyMedia)

        case simulateReplyAfterSend
        case _appendReply(ChatMessage)
    }

    @Dependency(\.continuousClock) var clock

    public var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                return .none

            case .plusTapped:
                state.isTrayPresented = true
                return .none

            case .trayDismissed:
                state.isTrayPresented = false
                return .none

            case .sendTapped:
                let text = state.draftText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return .none }

                state.draftText = ""
                state.messages.append(
                    ChatMessage(
                        id: UUID(),
                        isMe: true,
                        sentAt: Date(),
                        kind: .text(text)
                    )
                )

                // Mirror “demo chat” feel: auto reply.
                return .send(.simulateReplyAfterSend)

            case let .trayMediaSelected(media):
                state.isTrayPresented = false
                state.messages.append(
                    ChatMessage(
                        id: UUID(),
                        isMe: true,
                        sentAt: Date(),
                        kind: .media(media)
                    )
                )

                // Mirror “demo chat” feel: auto reply.
                return .send(.simulateReplyAfterSend)

            case .simulateReplyAfterSend:
                // Fake a reply after a short delay so it feels like the Android demo.
                return .run { send in
                    try await clock.sleep(for: .milliseconds(650))
                    await send(._appendReply(ChatSeed.randomReply()))
                }

            case let ._appendReply(message):
                state.messages.append(message)
                return .none
            }
        }
    }
}
