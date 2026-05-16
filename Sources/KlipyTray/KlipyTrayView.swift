//
//  KlipyTrayView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 12/17/25.
//

import SwiftUI
import KlipyCore
import KlipyUI
import SDWebImageSwiftUI
import ComposableArchitecture

/// A keyboard-friendly Klipy tray that supports:
/// - Search bar pinned to top
/// - Media-type tabs pinned under search
/// - Full-height scrolling grid beneath
///
/// Powered by `KlipyTrayFeature` (TCA).
public struct KlipyTrayView: View {
    
    @Environment(\.openURL) private var openURL

    @ComposableArchitecture.Bindable public var store: StoreOf<KlipyTrayFeature>

    private let onSelect: (KlipyMedia) -> Void
    private let onError: (String) -> Void

    public init(
        store: StoreOf<KlipyTrayFeature>,
        onSelect: @escaping (KlipyMedia) -> Void,
        onError: @escaping (String) -> Void = { _ in }
    ) {
        self.store = store
        self.onSelect = onSelect
        self.onError = onError
        KlipyUIBootstrap.configureIfNeeded()
    }

    /// Convenience init if you don't want to build a store.
    public init(
        client: KlipyClient,
        config: KlipyTrayConfig = .init(),
        onSelect: @escaping (KlipyMedia) -> Void,
        onError: @escaping (String) -> Void = { _ in }
    ) {
        self.init(
            store: Store(initialState: KlipyTrayFeature.State(config: config)) {
                KlipyTrayFeature(client: client)
            },
            onSelect: onSelect,
            onError: onError
        )
    }

    public var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                if store.config.showSearch {
                    searchBar
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                }

                tabsBar
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                if store.config.showCategories, !store.categories.isEmpty {
                    categoriesBar
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }

                contentGrid
                
                poweredByBar
            }
            .background(Color(.systemBackground))
            .onAppear {
                store.send(.onAppear)
            }
            .onChange(of: store.errorMessage) { message in
                guard let message, !store.isOffline else { return }
                onError(message)
                store.send(.dismissError)
            }
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.secondary)

            TextField(
                "Search",
                text: Binding(
                    get: { store.searchInput },
                    set: { store.send(.searchInputChanged($0)) }
                )
            )
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .submitLabel(.search)
            .onSubmit {
              store.send(.searchSubmitted)
            }

            if !store.searchInput.isEmpty {
                Button {
                  store.send(.clearSearchTapped)
                } label: {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Tabs

    private var tabsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.mediaTabs, id: \.rawValue) { tab in
                    let selected = (store.chosenTab == tab)
                    Button {
                        store.send(.tabSelected(tab))
                    } label: {
                        Text(tab.title)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selected ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Categories

    private var categoriesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    store.send(.categorySelected(nil))
                } label: {
                    Text("All")
                        .font(.system(size: 13, weight: store.chosenCategory == nil ? .semibold : .regular))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(store.chosenCategory == nil ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
                        )
                }
                .buttonStyle(.plain)

                ForEach(store.categories) { cat in
                    let selected = (store.chosenCategory?.id == cat.id)
                    Button {
                        store.send(.categorySelected(cat))
                    } label: {
                        Text(cat.category)
                            .lineLimit(1)
                            .font(.system(size: 13, weight: selected ? .semibold : .regular))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selected ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Grid

    private var contentGrid: some View {
        Group {
            if store.isOffline && store.mediaItems.isEmpty {
                KlipyOfflineStateView {
                    store.send(.retryTapped)
                }
            } else {
                ZStack {
                    KlipyMasonryFeedView(
                        items: store.mediaItems,
                        metadata: store.layoutMetadata,
                        maxItemsPerRow: store.config.maxItemsPerRow,
                        spacing: 0,
                        onLoadMore: { item in
                            if item.id == store.mediaItems.last?.id {
                                store.send(.loadNextPage)
                            }
                        }
                    ) { media in
                        Button { onSelect(media) } label: {
                            KlipyTrayCell(item: media)
                        }
                        .buttonStyle(.plain)
                    } advertisementTile: { advertisement in
                        KlipyAdvertisementView(advertisement: advertisement)
                    } footer: {
                        if store.isFetchingNextPage {
                            ProgressView()
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.top, 2)
                    .padding(.bottom, 8)

                    if store.isLoading && store.mediaItems.isEmpty {
                        ProgressView()
                    }
                }
            }
        }
    }
    
    // MARK: - Powered by Bar
    
    private var poweredByBar: some View {
        VStack(spacing: 0) {
            Button {
                if let url = store.config.brandURL {
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
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .background(Color.white)
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .accessibilityLabel("Open Klipy website")
        }
        .frame(height: 5)
    }
}

private struct KlipyTrayCell: View {
    let item: KlipyMedia

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.secondarySystemBackground)

            if let url = item.previewURL {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(item.displayAspectRatio, contentMode: .fill)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }

            if item.type == .clip {
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

struct KlipyTrayView_Previews: PreviewProvider {
    static var previews: some View {
        let client = KlipyClient(configuration: .init(apiKey: ""))

        Group {
            KlipyTrayView(
                client: client,
                config: .init(
                    mediaTabs: [.gifs, .stickers, .clips, .memes, .emojis],
                    initialTab: .gifs,
                    maxItemsPerRow: 3,
                    showTrending: true,
                    showRecents: false,
                    showCategories: true,
                    showSearch: true
                ),
                onSelect: { _ in },
                onError: { _ in }
            )
            .previewDisplayName("Tray — Trending")

            KlipyTrayView(
                client: client,
                config: .init(
                    mediaTabs: [.gifs, .stickers],
                    initialTab: .stickers,
                    maxItemsPerRow: 4,
                    showTrending: false,
                    showRecents: true,
                    showCategories: false,
                    showSearch: true
                ),
                onSelect: { _ in },
                onError: { _ in }
            )
            .previewDisplayName("Tray — Recents (no categories)")
        }
        .frame(height: 360)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
