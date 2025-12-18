//
//  MessageRow.swift
//  KlipyChatTCA
//
//  Created by Cortland Walker on 12/17/25.
//

import SwiftUI
import KlipyCore
import SDWebImageSwiftUI
import KlipyUI

struct MessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isMe { Spacer(minLength: 40) }

            bubble
                .frame(maxWidth: 280, alignment: message.isMe ? .trailing : .leading)

            if !message.isMe { Spacer(minLength: 40) }
        }
    }

    private var bubble: some View {
        Group {
            switch message.kind {
            case let .text(text):
                Text(text)
                    .font(.system(size: 16))
                    .foregroundStyle(message.isMe ? Color.white : Color.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(message.isMe ? Color.blue : Color(.secondarySystemBackground))
                    )

            case let .media(media):
                KlipyMediaPreviewView(media: media)
                  .frame(width: 240, height: 180)
                  .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}

private struct MediaBubble: View {
    let media: KlipyMedia
    let isMe: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let url = media.previewURL {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .scaledToFill()
                    .frame(width: 220, height: 160)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 220, height: 160)
            }

            if let title = media.title {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isMe ? Color.blue.opacity(0.14) : Color(.secondarySystemBackground))
        )
    }
}
