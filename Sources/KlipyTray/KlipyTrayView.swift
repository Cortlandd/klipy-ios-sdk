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

/// A keyboard-friendly Klipy tray, modeled after the Android tray:
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
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                }

                tabsBar
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)

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
                guard let message else { return }
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
        ZStack {
            ScrollView {
                LazyVGrid(
                  columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: store.config.columns),
                  spacing: 10
                ) {
                  ForEach(store.mediaItems, id: \.id) { item in
                    Button { onSelect(item) } label: {
                      KlipyTrayCell(item: item)
                        .aspectRatio(item.displayAspectRatio, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                      if item.id == store.mediaItems.last?.id {
                        store.send(.loadNextPage)
                      }
                    }
                  }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

                if store.isFetchingNextPage {
                    ProgressView()
                        .padding(.vertical, 12)
                }
            }

            if store.isLoading && store.mediaItems.isEmpty {
                ProgressView()
            }
        }
    }
    
    // MARK: - Powered by Bar
    
    private var poweredByBar: some View {
        VStack(spacing: 0) {
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
    GeometryReader { geo in
      let width = geo.size.width
      let height = width / max(0.75, min(item.displayAspectRatio, 1.9))

      ZStack {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Color(.secondarySystemBackground))

        if let url = item.previewURL {
          WebImage(url: url)
            .resizable()
            .indicator(.activity)
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
        }
      }
      .frame(width: width, height: height)
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    .frame(height: 120) // temporary; overridden by parent using `.aspectRatio` below
  }
}


#if DEBUG
import SwiftUI
import ComposableArchitecture
import KlipyCore
import KlipyTray

struct KlipyTrayView_Previews: PreviewProvider {
    static var previews: some View {
        let client = KlipyClient(configuration: .init(apiKey: ""))

        Group {
            KlipyTrayView(
                client: client,
                config: .init(
                    mediaTabs: [.gifs, .stickers, .clips, .memes],
                    initialTab: .gifs,
                    columns: 3,
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
                    columns: 4,
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
