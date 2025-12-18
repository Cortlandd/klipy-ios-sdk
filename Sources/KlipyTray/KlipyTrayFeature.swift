//
//  KlipyTrayFeature.swift
//  KlipySDK
//
//  Created by Cortland Walker on 12/17/25.
//

import Foundation
import KlipyCore
import KlipyUI
import ComposableArchitecture

/// TCA-powered tray feature, modeled after the Android tray reducer.
///
/// Responsibilities:
/// - Manage tray state (selected tab, query, paging, optional categories).
/// - Perform networking via `KlipyClient`.
///
/// Notably *not* responsible for:
/// - Emitting a "media chosen" effect. The view calls `onSelect` directly.
@Reducer
public struct KlipyTrayFeature: Sendable {

    public init(client: KlipyClient) {
        self.client = client
    }

    private let client: KlipyClient

    // MARK: - State

    @ObservableState
    public struct State: Equatable, Sendable {
        public var config: KlipyTrayConfig

        public var isLoading: Bool = false
        public var errorMessage: String? = nil

        public var mediaTabs: [KlipyPickerMediaTab] = []
        public var chosenTab: KlipyPickerMediaTab? = nil

        public var categories: [KlipyCategory] = []
        public var chosenCategory: KlipyCategory? = nil

        public var mediaItems: [KlipyMedia] = []

        public var searchInput: String = ""
        public var lastSearchedInput: String? = nil

        // Paging
        public var currentPage: Int = 1
        public var hasNext: Bool = true
        public var isFetchingNextPage: Bool = false

        public init(config: KlipyTrayConfig = .init()) {
            self.config = config
        }
    }

    // MARK: - Action

    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)

        case onAppear
        case tabSelected(KlipyPickerMediaTab)
        case categorySelected(KlipyCategory?)
        case searchInputChanged(String)
        case loadNextPage
        case searchSubmitted
        case clearSearchTapped

        case dismissError

        case _loadedCategories([KlipyCategory])
        case _loadedPage(KlipyPage<KlipyMedia>, reset: Bool)
        case _failed(String)
    }

    private enum CancelID: Hashable {
        case fetch
        case categories
    }

    // MARK: - Reducer

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {

            case .onAppear:
                let tabs = state.config.mediaTabs
                let initial: KlipyPickerMediaTab? = {
                    if tabs.contains(state.config.initialTab) { return state.config.initialTab }
                    return tabs.first
                }()

                state.mediaTabs = tabs
                state.chosenTab = initial
                state.isLoading = true
                state.errorMessage = nil
                state.categories = []
                state.chosenCategory = nil
                state.mediaItems = []
                state.searchInput = ""
                state.lastSearchedInput = nil
                state.currentPage = 1
                state.hasNext = true
                state.isFetchingNextPage = false

                guard let initial else {
                    state.isLoading = false
                    return .none
                }
                return .send(.tabSelected(initial))

            case let .tabSelected(tab):
                state.chosenTab = tab
                state.chosenCategory = nil
                state.mediaItems = []
                state.currentPage = 1
                state.hasNext = true
                state.isFetchingNextPage = false
                state.isLoading = true
                state.errorMessage = nil

                let kind = tab.mediaType

                let categoriesEffect: Effect<Action> =
                    state.config.showCategories
                    ? .run { [client] send in
                        do {
                            let cats = try await client.categories(kind: kind)
                            await send(._loadedCategories(cats))
                        } catch {
                            await send(._failed(error.localizedDescription.isEmpty ? "Failed to load categories." : error.localizedDescription))
                            await send(._loadedCategories([]))
                        }
                    }
                    .cancellable(id: CancelID.categories, cancelInFlight: true)
                    : .send(._loadedCategories([]))

                let fetchEffect: Effect<Action> = fetch(
                    reset: true,
                    tab: tab,
                    query: state.searchInput,
                    chosenCategory: nil,
                    page: 1,
                    config: state.config
                )
                .cancellable(id: CancelID.fetch, cancelInFlight: true)

                return .merge(categoriesEffect, fetchEffect)

            case let .categorySelected(category):
                state.chosenCategory = category
                state.searchInput = ""
                state.lastSearchedInput = category?.category

                guard let tab = state.chosenTab ?? state.mediaTabs.first else { return .none }

                state.mediaItems = []
                state.currentPage = 1
                state.hasNext = true
                state.isFetchingNextPage = false
                state.isLoading = true
                state.errorMessage = nil

                return fetch(
                    reset: true,
                    tab: tab,
                    query: "", // ignored when category provides filter, see fetch() update below
                    chosenCategory: category,
                    page: 1,
                    config: state.config
                )
                .cancellable(id: CancelID.fetch, cancelInFlight: true)

            case let .searchInputChanged(raw):
                state.searchInput = raw
                    .replacingOccurrences(of: "\n", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return .none
                
                let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                state.searchInput = query

                guard state.config.showSearch else { return .none }
                guard let tab = state.chosenTab ?? state.mediaTabs.first else { return .none }

                state.mediaItems = []
                state.currentPage = 1
                state.hasNext = true
                state.isFetchingNextPage = false
                state.isLoading = true
                state.errorMessage = nil

                if query.isEmpty {
                    state.lastSearchedInput = nil
                    return fetch(reset: true, tab: tab, query: "", chosenCategory: state.chosenCategory, page: 1, config: state.config)
                        .cancellable(id: CancelID.fetch, cancelInFlight: true)
                } else {
                    state.lastSearchedInput = query
                    return fetch(reset: true, tab: tab, query: query, chosenCategory: state.chosenCategory, page: 1, config: state.config)
                        .cancellable(id: CancelID.fetch, cancelInFlight: true)
                }
            case .searchSubmitted:
              guard state.config.showSearch else { return .none }
              guard let tab = state.chosenTab ?? state.mediaTabs.first else { return .none }

              let query = state.searchInput.trimmingCharacters(in: .whitespacesAndNewlines)

              // Match Android-ish behavior: submitting search clears category selection
              // (optional, but recommended so chips don't fight with text search)
              state.chosenCategory = nil

              state.mediaItems = []
              state.currentPage = 1
              state.hasNext = true
              state.isFetchingNextPage = false
              state.isLoading = true
              state.errorMessage = nil

              state.lastSearchedInput = query.isEmpty ? nil : query

              return fetch(
                reset: true,
                tab: tab,
                query: query,
                chosenCategory: nil,
                page: 1,
                config: state.config
              )
              .cancellable(id: CancelID.fetch, cancelInFlight: true)
            case .clearSearchTapped:
              state.searchInput = ""
              state.lastSearchedInput = nil

              guard let tab = state.chosenTab ?? state.mediaTabs.first else { return .none }

              // When clearing, go back to default feed (trending/recent per config).
              state.mediaItems = []
              state.currentPage = 1
              state.hasNext = true
              state.isFetchingNextPage = false
              state.isLoading = true
              state.errorMessage = nil

              return fetch(
                reset: true,
                tab: tab,
                query: "",
                chosenCategory: state.chosenCategory,
                page: 1,
                config: state.config
              )
              .cancellable(id: CancelID.fetch, cancelInFlight: true)

            case .loadNextPage:
                guard let tab = state.chosenTab ?? state.mediaTabs.first else { return .none }
                guard !state.isFetchingNextPage, state.hasNext else { return .none }

                state.isFetchingNextPage = true
                let nextPage = state.currentPage + 1
                return fetch(reset: false, tab: tab, query: state.searchInput, chosenCategory: state.chosenCategory, page: nextPage, config: state.config)
                    .cancellable(id: CancelID.fetch, cancelInFlight: false)

            case .dismissError:
                state.errorMessage = nil
                return .none

            case let ._loadedCategories(cats):
                state.categories = cats

                if state.config.showTrending {
                    let trending = cats.first(where: { ($0.category ?? "").lowercased() == "trending" })
                    state.chosenCategory = trending
                }

                return .none

            case let ._loadedPage(page, reset):
                if reset {
                    state.mediaItems = page.data
                } else {
                    state.mediaItems.append(contentsOf: page.data)
                }
                state.currentPage = page.currentPage
                state.hasNext = page.hasNext
                state.isLoading = false
                state.isFetchingNextPage = false
                return .none

            case let ._failed(message):
                state.isLoading = false
                state.isFetchingNextPage = false
                state.errorMessage = message
                return .none

            case .binding:
                return .none
            }
        }
    }

    // MARK: - Fetch

    private func fetch(
        reset: Bool,
        tab: KlipyPickerMediaTab,
        query: String,
        chosenCategory: KlipyCategory?,
        page: Int,
        config: KlipyTrayConfig
    ) -> Effect<Action> {
        .run { [client] send in
            do {
                let kind = tab.mediaType
                let perPage = client.configuration.defaultPerPage
                let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
                let categoryFilter = chosenCategory?.category.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let filter = !categoryFilter.isEmpty ? categoryFilter : trimmedQuery

                // If there's no filter at all, we follow emptyQueryFeed.
                if filter.isEmpty, config.emptyQueryFeed == .none {
                    await send(._loadedPage(KlipyPage(data: [], currentPage: 1, perPage: (perPage ?? 24), hasNext: false), reset: reset))
                    return
                }

                let result: KlipyPage<KlipyMedia>

                if filter.isEmpty {
                    // empty -> trending/recent
                    switch config.emptyQueryFeed {
                    case .trending:
                        result = try await client.trending(kind: kind, page: page, perPage: perPage)
                    case .recent:
                        result = try await client.recent(kind: kind, page: page, perPage: perPage)
                    case .none:
                        result = KlipyPage(data: [], currentPage: 1, perPage: (perPage ?? 24), hasNext: false)
                    }
                } else {
                    // If the chip is literally "trending" or "recent", route to those endpoints
                    if filter.caseInsensitiveCompare("trending") == .orderedSame {
                        result = try await client.trending(kind: kind, page: page, perPage: perPage)
                    } else if filter.caseInsensitiveCompare("recent") == .orderedSame {
                        result = try await client.recent(kind: kind, page: page, perPage: perPage)
                    } else {
                        // Otherwise: search using the chip string or typed query
                        result = try await client.search(kind: kind, query: filter, page: page, perPage: perPage)
                    }
                }

                await send(._loadedPage(result, reset: reset))
            } catch {
                await send(._failed(error.localizedDescription.isEmpty ? "Failed to load Klipy content." : error.localizedDescription))
            }
        }
    }
}

