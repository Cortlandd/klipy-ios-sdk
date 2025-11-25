//
//  KlipyMediaPreview.swift
//  KlipySampleTCA
//
//  Created by Cortland Walker on 11/24/25.
//

import SwiftUI
import SDWebImageSwiftUI
import KlipyCore
import AVFoundation
import AVKit

public struct KlipyMediaPreview: View {
    let media: KlipyMedia

    @State private var player: AVPlayer?
    @State private var isMuted: Bool = true

    public var body: some View {
        Group {
            switch media.type {
            case .clip:
                clipPlayer
            case .gif, .sticker, .meme:
                imagePreview
            }
        }
    }

    // MARK: - Clip playback with sound

    private var clipPlayer: some View {
        VStack(spacing: 8) {
            if let url = media.mp4URL {
                VideoPlayer(player: player)
                    .onAppear {
                        if player == nil {
                            let p = AVPlayer(url: url)
                            p.isMuted = isMuted
                            p.play()
                            player = p
                        } else {
                            player?.play()
                        }
                    }
                    .onDisappear {
                        player?.pause()
                    }
                    .aspectRatio(media.displayAspectRatio, contentMode: .fit)
                    .cornerRadius(10)
            } else if let url = media.previewURL {
                // Fallback: just show the still with no sound
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(media.displayAspectRatio, contentMode: .fit)
                    .cornerRadius(10)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }

            // Mute toggle actually wired to AVPlayer
            HStack {
                Button {
                    isMuted.toggle()
                    player?.isMuted = isMuted
                } label: {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.headline)
                }

                Text(isMuted ? "Muted" : "Sound on")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Non-clip media

    private var imagePreview: some View {
        VStack {
            if let url = media.previewURL {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(media.displayAspectRatio, contentMode: .fit)
                    .cornerRadius(10)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
    }
}
