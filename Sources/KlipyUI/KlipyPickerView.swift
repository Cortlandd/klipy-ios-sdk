//
//  KlipyPickerView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import SwiftUI
import KlipyCore
import SDWebImageSwiftUI
import ComposableArchitecture

public struct KlipyPickerView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    public let store: StoreOf<KlipyPickerFeature>
    private let onSelect: (KlipyMedia) -> Void
    private let onClose: (() -> Void)?
    @State private var confirmationMedia: KlipyMedia?
    
    // Global mute state for clips in this picker
    @State private var isClipsMuted: Bool = true

    public init(
        client: KlipyClient,
        config: KlipyPickerConfig = .init(),
        onSelect: @escaping (KlipyMedia) -> Void,
        onClose: (() -> Void)? = nil
    ) {
        self.store = Store(initialState: KlipyPickerFeature.State(config: config)) {
            KlipyPickerFeature(
                client: client,
                locale: client.configuration.defaultLocale ?? Locale.autoupdatingCurrent.identifier,
                perPage: client.configuration.defaultPerPage ?? 24
            )
        }
        KlipyUIBootstrap.configureIfNeeded()
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public init(
        store: StoreOf<KlipyPickerFeature>,
        onSelect: @escaping (KlipyMedia) -> Void,
        onClose: (() -> Void)? = nil
    ) {
        self.store = store
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
        WithPerceptionTracking {
            VStack(spacing: 0) {
                topHandleBar

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
            .background(containerBackground)
            .onAppear {
                store.send(.onAppear)
            }
            .sheet(item: $confirmationMedia) { media in
                KlipyMediaConfirmationView(
                    media: media,
                    theme: store.config.theme,
                    onSelect: {
                        confirmationMedia = nil
                        onSelect(media)
                    },
                    onClose: {
                        confirmationMedia = nil
                    }
                )
            }
        }
    }

    private var palette: KlipyThemePalette {
        store.config.theme.palette(for: colorScheme)
    }

    // MARK: - Top handle

    private var topHandleBar: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(palette.secondaryText.opacity(0.35))
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
                .foregroundColor(palette.separator)
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
                        .foregroundStyle(palette.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .background(poweredByBackground)
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .accessibilityLabel("Open Klipy website")
        }
    }

    // MARK: - Tabs

    private var tabSelector: some View {
        Picker("Type", selection: Binding(
            get: { store.selectedTab },
            set: { store.send(.tabSelected($0)) }
        )) {
            ForEach(store.config.mediaTabs, id: \.self) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Search

    private var searchField: some View {
        HStack {
            TextField("Search", text: Binding(
                get: { store.query },
                set: { store.send(.queryChanged($0)) }
            ))
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .submitLabel(.search)
            .foregroundStyle(palette.primaryText)
            .onSubmit {
                store.send(.searchSubmitted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(palette.secondarySurface)
            )
            .overlay(
                HStack {
                    Spacer()
                    if !store.query.isEmpty {
                        Button {
                            store.send(.clearSearchTapped)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(palette.secondaryText)
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
            if store.isLoading && store.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = store.errorMessage, store.items.isEmpty {
                if store.isOffline {
                    KlipyOfflineStateView {
                        store.send(.retryTapped)
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("Failed to load Klipy content.")
                            .font(.callout)
                            .foregroundStyle(palette.primaryText)
                        Text(errorMessage)
                            .font(.caption2)
                            .foregroundColor(palette.secondaryText)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            store.send(.retryTapped)
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
            items: store.items,
            metadata: store.layoutMetadata,
            maxItemsPerRow: store.config.maxItemsPerRow,
            spacing: 0,
            onLoadMore: { item in
                store.send(.loadMoreIfNeeded(item.id))
            }
        ) { media in
            Button {
                if store.config.showConfirmationScreen {
                    confirmationMedia = media
                } else {
                    onSelect(media)
                }
            } label: {
                KlipyThumbnailView(media: media, isClipsMuted: $isClipsMuted)
            }
            .buttonStyle(.plain)
        } advertisementTile: { advertisement in
            KlipyAdvertisementView(advertisement: advertisement)
        } footer: {
            if store.isLoading && !store.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private var containerBackground: some View {
        if palette.chromeMaterial != nil {
            Rectangle()
                .fill(palette.chromeMaterial ?? .regularMaterial)
                .ignoresSafeArea()
        } else {
            palette.background
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var poweredByBackground: some View {
        if palette.chromeMaterial != nil {
            Rectangle().fill(palette.chromeMaterial ?? .regularMaterial)
        } else {
            palette.surface
        }
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
