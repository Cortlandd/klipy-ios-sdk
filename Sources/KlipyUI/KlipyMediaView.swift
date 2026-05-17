//
//  KlipyMediaView.swift
//  KlipySDK
//
//  Created by Codex on 5/16/26.
//

import UIKit
import SwiftUI
import AVKit
import KlipyCore
import SDWebImageSwiftUI

@MainActor
public final class KlipyMediaView: UIView {
    public var media: KlipyMedia? {
        didSet {
            updateRootView()
        }
    }

    public var cornerRadius: CGFloat = 0 {
        didSet {
            hostedView.layer.cornerRadius = cornerRadius
            hostedView.layer.masksToBounds = cornerRadius > 0
        }
    }

    private let hostingController = UIHostingController(rootView: AnyView(Color.clear))

    public init(media: KlipyMedia? = nil) {
        self.media = media
        super.init(frame: .zero)
        backgroundColor = .clear
        embedHostingController()
        updateRootView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(with media: KlipyMedia?) {
        self.media = media
    }

    private var hostedView: UIView {
        hostingController.view
    }

    private func embedHostingController() {
        let hostedView = hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear

        addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func updateRootView() {
        hostingController.rootView = AnyView(KlipyMediaEmbeddedView(media: media))
    }
}

private struct KlipyMediaEmbeddedView: View {
    let media: KlipyMedia?

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.clear

            if let media {
                switch media.type {
                case .clip:
                    clipView(media: media)
                case .gif, .sticker, .meme, .emoji:
                    imageView(media: media)
                }
            }
        }
    }

    @ViewBuilder
    private func imageView(media: KlipyMedia) -> some View {
        if let url = media.previewURL {
            WebImage(url: url)
                .resizable()
                .indicator(.activity)
                .aspectRatio(media.displayAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func clipView(media: KlipyMedia) -> some View {
        if let url = media.mp4URL {
            VideoPlayer(player: player)
                .onAppear {
                    if player == nil {
                        let player = AVPlayer(url: url)
                        player.isMuted = true
                        player.play()
                        self.player = player
                    } else {
                        player?.play()
                    }
                }
                .onDisappear {
                    player?.pause()
                }
                .aspectRatio(media.displayAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            imageView(media: media)
        }
    }
}
