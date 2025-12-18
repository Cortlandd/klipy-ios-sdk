import Foundation
import KlipyCore

struct ChatMessage: Identifiable {
  enum Kind: Equatable {
    case text(String)
    case media(KlipyMedia)
  }

  let id: UUID
  let isMe: Bool
  let date: Date
  let kind: Kind
}

extension ChatMessage: Equatable {
  static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
    lhs.id == rhs.id
  }
}

extension ChatMessage: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

enum ChatSeed {

  static func sampleConversation() -> [ChatMessage] {
    let now = Date()
    func t(_ minutesAgo: Int) -> Date {
      Calendar.current.date(byAdding: .minute, value: -minutesAgo, to: now) ?? now
    }

    func seededGif(id: String, title: String, url: String) -> KlipyMedia {
      KlipyMedia(
        id: id,
        slug: id,
        type: .gif,
        title: title,
        file: KlipyMediaFile(
          hd: nil,
          md: nil,
          sm: KlipyMediaFileBucket(
            gif: KlipyMediaFileAsset(
              url: URL(string: url)!,
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
    }

    let demoGifs: [KlipyMedia] = [
      seededGif(id: "seed-1", title: "Hello", url: "https://media.giphy.com/media/ICOgUNjpvO0PC/giphy.gif"),
      seededGif(id: "seed-2", title: "Nice",  url: "https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif"),
      seededGif(id: "seed-3", title: "Wow",   url: "https://media.giphy.com/media/l0HlQ7LRal6m8k5lS/giphy.gif")
    ]

    return [
      .init(id: UUID(), isMe: false, date: t(28), kind: .text("yo")),
      .init(id: UUID(), isMe: true,  date: t(27), kind: .text("what’s good 😂")),
      .init(id: UUID(), isMe: false, date: t(26), kind: .text("try the tray thing")),
      .init(id: UUID(), isMe: true,  date: t(25), kind: .text("bet. opening it now…")),
      .init(id: UUID(), isMe: true,  date: t(24), kind: .media(demoGifs[0])),
      .init(id: UUID(), isMe: false, date: t(23), kind: .text("ok that’s actually fire")),
      .init(id: UUID(), isMe: true,  date: t(22), kind: .media(demoGifs[1])),
      .init(id: UUID(), isMe: false, date: t(21), kind: .text("send one more")),
      .init(id: UUID(), isMe: true,  date: t(20), kind: .media(demoGifs[2])),
      .init(id: UUID(), isMe: false, date: t(19), kind: .text("😂😂😂"))
    ]
  }
}
