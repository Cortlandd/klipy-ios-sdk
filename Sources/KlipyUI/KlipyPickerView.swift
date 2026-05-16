//
//  KlipyPickerView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import SwiftUI
import KlipyCore
import SDWebImageSwiftUI

public struct KlipyPickerView: View {
    @Environment(\.openURL) private var openURL

    @StateObject private var viewModel: KlipyPickerViewModel
    private let onSelect: (KlipyMedia) -> Void
    private let onClose: (() -> Void)?
    
    // Global mute state for clips in this picker
    @State private var isClipsMuted: Bool = true

    public init(
        client: KlipyClient,
        config: KlipyPickerConfig = .init(),
        onSelect: @escaping (KlipyMedia) -> Void,
        onClose: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: KlipyPickerViewModel(
                client: client,
                config: config
            )
        )
        KlipyUIBootstrap.configureIfNeeded()
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public init(
        client: KlipyClient,
        availableTabs: [KlipyPickerMediaTab] = KlipyPickerMediaTab.allCases,
        initialTab: KlipyPickerMediaTab = .gifs,
        onSelect: @escaping (KlipyMedia) -> Void,
        onClose: (() -> Void)? = nil
    ) {
        self.init(
            client: client,
            config: KlipyPickerConfig(
                mediaTabs: availableTabs,
                initialTab: initialTab
            ),
            onSelect: onSelect,
            onClose: onClose
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            topHandleBar

            // Main content
            VStack(spacing: 6) {
                tabSelector
                searchField
                content
            }
            .padding(.horizontal, 8)

            poweredByBar
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
        .onAppear {
            viewModel.loadInitial()
        }
    }

    // MARK: - Top handle

    private var topHandleBar: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 4)
                .padding(.vertical, 6)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onClose?()
        }
        .accessibilityLabel("Close Klipy picker")
    }

    // MARK: - Bottom "Powered by Klipy"

    private var poweredByBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray)
            Button {
                if let url = URL(string: "https://klipy.com/en-US") {
                    openURL(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(.klipyLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text("Powered by Klipy")
                        .font(.footnote.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .background(Color.white)
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .accessibilityLabel("Open Klipy website")
        }
    }

    // MARK: - Tabs

    private var tabSelector: some View {
        Picker("Type", selection: Binding(
            get: { viewModel.selectedTab },
            set: { viewModel.didChangeTab($0) }
        )) {
            ForEach(viewModel.config.mediaTabs, id: \.self) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Search

    private var searchField: some View {
        HStack {
            TextField("Search", text: Binding(
                get: { viewModel.query },
                set: { viewModel.updateQuery($0) }
            ))
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .submitLabel(.search)
            .onSubmit {
                viewModel.submitSearch()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                HStack {
                    Spacer()
                    if !viewModel.query.isEmpty {
                        Button {
                            viewModel.updateQuery("")
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            )
        }
    }

    // MARK: - Content

    private var content: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.lastError, viewModel.items.isEmpty {
                if error.isConnectivityError {
                    KlipyOfflineStateView {
                        viewModel.loadInitial()
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("Failed to load Klipy content.")
                            .font(.callout)
                        Text(error.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel.loadInitial()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                scrollGrid
            }
        }
    }

    private var scrollGrid: some View {
        KlipyMasonryFeedView(
            items: viewModel.items,
            metadata: viewModel.layoutMetadata,
            maxItemsPerRow: viewModel.config.maxItemsPerRow,
            spacing: 0,
            onLoadMore: { item in
                viewModel.loadMoreIfNeeded(currentItem: item)
            }
        ) { media in
            Button {
                onSelect(media)
            } label: {
                KlipyThumbnailView(media: media, isClipsMuted: $isClipsMuted)
            }
            .buttonStyle(.plain)
        } advertisementTile: { advertisement in
            KlipyAdvertisementView(advertisement: advertisement)
        } footer: {
            if viewModel.isLoading && !viewModel.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(.top, 2)
    }
}

// MARK: - Thumbnail tile

struct KlipyThumbnailView: View {
    let media: KlipyMedia
    @Binding var isClipsMuted: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemGray6)

            if let url = media.previewURL {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(media.displayAspectRatio, contentMode: .fill)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }

            if media.type == .clip {
                Image(systemName: "play.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(6)
            }
        }
        .clipped()
    }
}

#if DEBUG
import SwiftUI
import KlipyCore
@available(iOS 14.0, *)
struct KlipyPickerView_Previews: PreviewProvider {
    static var previews: some View {
        // For now we just use a live client with a fake key.
        // In the preview canvas this will typically just show the loading state
        // (or real content if you plug in a valid key).
        let client = KlipyClient.live(apiKey: "DEMO_PREVIEW_KEY")

        KlipyPickerView(
            client: client,
            config: KlipyPickerConfig(
                mediaTabs: [.gifs, .stickers, .clips, .memes, .emojis],
                maxItemsPerRow: 3,
                showRecents: false,
                showTrending: true,
                initialTab: .gifs
            ),
            onSelect: { media in
                print(media)
            },
            onClose: {
                print("close")
            }
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif
