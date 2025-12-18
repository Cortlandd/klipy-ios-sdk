//
//  ChatMessage.swift
//  KlipyChatTCA
//
//  Created by Cortland Walker on 12/17/25.
//

import Foundation
import KlipyCore
import KlipyUI
import KlipyTray

public struct ChatMessage: Equatable, Identifiable {
    public enum Kind: Equatable {
        case text(String)
        case media(KlipyMedia)
    }

    public let id: UUID
    public let isMe: Bool
    public let sentAt: Date
    public let kind: Kind

    public init(id: UUID, isMe: Bool, sentAt: Date, kind: Kind) {
        self.id = id
        self.isMe = isMe
        self.sentAt = sentAt
        self.kind = kind
    }
}

public enum ChatSeed {

    /// Seeded “demo chat” conversation like the Android sample.
    static let sampleConversation: [ChatMessage] = {
        let now = Date()
        func t(_ minutesAgo: Int) -> Date {
            Calendar.current.date(byAdding: .minute, value: -minutesAgo, to: now) ?? now
        }

        // NOTE: these media URLs are just stable public gif URLs for demo purposes.
        // In your real demo you’ll pick from Klipy trending anyway.
        let demoGifs: [KlipyMedia] = [
          KlipyMedia(
            id: "seed-1",
            slug: "seed-1",
            type: .gif,
            title: "Hello",
            file: KlipyMediaFile(
              hd: nil,
              md: nil,
              sm: KlipyMediaFileBucket(
                gif: KlipyMediaFileAsset(
                  url: URL(string: "https://media.giphy.com/media/ICOgUNjpvO0PC/giphy.gif")!,
                  width: nil,
                  height: nil,
                  sizeBytes: nil
                ),
                webp: nil,
                jpg: nil,
                mp4: nil,
                webm: nil
              ),
              xs: nil,
              mp4: nil,
              gif: nil,
              webp: nil
            )
          ),
          KlipyMedia(
            id: "seed-2",
            slug: "seed-2",
            type: .gif,
            title: "Nice",
            file: KlipyMediaFile(
              hd: nil,
              md: nil,
              sm: KlipyMediaFileBucket(
                gif: KlipyMediaFileAsset(
                  url: URL(string: "https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif")!,
                  width: nil,
                  height: nil,
                  sizeBytes: nil
                ),
                webp: nil,
                jpg: nil,
                mp4: nil,
                webm: nil
              ),
              xs: nil,
              mp4: nil,
              gif: nil,
              webp: nil
            )
          ),
          KlipyMedia(
            id: "seed-3",
            slug: "seed-3",
            type: .gif,
            title: "Wow",
            file: KlipyMediaFile(
              hd: nil,
              md: nil,
              sm: KlipyMediaFileBucket(
                gif: KlipyMediaFileAsset(
                  url: URL(string: "https://media.giphy.com/media/l0HlQ7LRal6m8k5lS/giphy.gif")!,
                  width: nil,
                  height: nil,
                  sizeBytes: nil
                ),
                webp: nil,
                jpg: nil,
                mp4: nil,
                webm: nil
              ),
              xs: nil,
              mp4: nil,
              gif: nil,
              webp: nil
            )
          )
        ]


        return [
            .init(id: UUID(), isMe: false, sentAt: t(28), kind: .text("yo")),
            .init(id: UUID(), isMe: true,  sentAt: t(27), kind: .text("what’s good 😂")),
            .init(id: UUID(), isMe: false, sentAt: t(26), kind: .text("try that new tray thing")),
            .init(id: UUID(), isMe: true,  sentAt: t(25), kind: .text("bet. opening it now…")),
            .init(id: UUID(), isMe: true,  sentAt: t(24), kind: .media(demoGifs[0])),
            .init(id: UUID(), isMe: false, sentAt: t(23), kind: .text("ok that’s actually fire")),
            .init(id: UUID(), isMe: true,  sentAt: t(22), kind: .media(demoGifs[1])),
            .init(id: UUID(), isMe: false, sentAt: t(21), kind: .text("send one more")),
            .init(id: UUID(), isMe: true,  sentAt: t(20), kind: .media(demoGifs[2])),
            .init(id: UUID(), isMe: false, sentAt: t(19), kind: .text("😂😂😂"))
        ]
    }()

    static func randomReply() -> ChatMessage {
        let replies = [
            "lol",
            "ok now you’re cooking",
            "nahhhhh 😂",
            "send another",
            "that one’s perfect",
            "😂😂😂",
            "ok I’m stealing that"
        ]
        let text = replies.randomElement() ?? "lol"
        return .init(id: UUID(), isMe: false, sentAt: Date(), kind: .text(text))
    }
}
