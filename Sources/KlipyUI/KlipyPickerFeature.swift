//
//  KlipyPickerFeature.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/17/26.
//

import Foundation
import KlipyCore
import ComposableArchitecture

@Reducer
public struct KlipyPickerFeature: Sendable {
    public init(
        client: KlipyClient,
        locale: String = Locale.autoupdatingCurrent.identifier,
        perPage: Int = 24,
        searchDebounceNanoseconds: UInt64 = 350_000_000
    ) {
        self.client = client
        self.locale = locale
        self.perPage = perPage
        self.searchDebounceNanoseconds = searchDebounceNanoseconds
    }

    let client: any KlipyMediaLoading
    let locale: String
    let perPage: Int
    let searchDebounceNanoseconds: UInt64

    init(
        client: any KlipyMediaLoading,
        locale: String = Locale.autoupdatingCurrent.identifier,
        perPage: Int = 24,
        searchDebounceNanoseconds: UInt64 = 350_000_000
    ) {
        self.client = client
        self.locale = locale
        self.perPage = perPage
        self.searchDebounceNanoseconds = searchDebounceNanoseconds
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public var config: KlipyPickerConfig
        public var selectedTab: KlipyPickerMediaTab
        public var query = ""
        public var items: [KlipyContentItem] = []
        public var layoutMetadata: KlipyPageMeta?
        public var isLoading = false
        public var isOffline = false
        public var errorMessage: String?
        public var currentPage = 1
        public var hasNextPage = true
        public var isLoadingMore = false
        public var hasLoadedOnce = false

        public init(config: KlipyPickerConfig = .init()) {
            let resolvedTabs = config.mediaTabs.isEmpty ? KlipyPickerMediaTab.allCases : config.mediaTabs
            let resolvedInitialTab = resolvedTabs.contains(config.initialTab) ? config.initialTab : resolvedTabs[0]
            self.config = KlipyPickerConfig(
                mediaTabs: resolvedTabs,
                maxItemsPerRow: config.maxItemsPerRow,
                locale: config.locale,
                showRecents: config.showRecents,
                showTrending: config.showTrending,
                initialTab: resolvedInitialTab,
                showConfirmationScreen: config.showConfirmationScreen,
                theme: config.theme
            )
            self.selectedTab = resolvedInitialTab
        }
    }

    public enum Action: Sendable {
        case onAppear
        case tabSelected(KlipyPickerMediaTab)
        case queryChanged(String)
        case clearSearchTapped
        case searchSubmitted
        case retryTapped
        case loadMoreIfNeeded(String)

        case _debouncedSearchReady
        case _loadedPage(KlipyPage<KlipyContentItem>, reset: Bool)
        case _failed(String, isOffline: Bool)
    }

    private enum CancelID: Hashable {
        case fetch
        case debounce
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoadedOnce else { return .none }
                state.hasLoadedOnce = true
                return reload(state: &state, resetQuery: false)

            case let .tabSelected(tab):
                guard state.config.mediaTabs.contains(tab) else { return .none }
                state.selectedTab = tab
                return reload(state: &state, resetQuery: true)

            case let .queryChanged(value):
                state.query = value
                    .replacingOccurrences(of: "\n", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if state.query.isEmpty {
                    return .merge(
                        .cancel(id: CancelID.debounce),
                        reload(state: &state, resetQuery: false)
                    )
                }

                return .run { [searchDebounceNanoseconds] send in
                    try await Task.sleep(nanoseconds: searchDebounceNanoseconds)
                    await send(._debouncedSearchReady)
                }
                .cancellable(id: CancelID.debounce, cancelInFlight: true)

            case .clearSearchTapped:
                state.query = ""
                return .merge(
                    .cancel(id: CancelID.debounce),
                    reload(state: &state, resetQuery: false)
                )

            case .searchSubmitted:
                return .merge(
                    .cancel(id: CancelID.debounce),
                    reload(state: &state, resetQuery: false)
                )

            case .retryTapped:
                return reload(state: &state, resetQuery: false)

            case let .loadMoreIfNeeded(itemID):
                guard state.hasNextPage,
                      !state.isLoading,
                      !state.isLoadingMore,
                      state.items.last?.id == itemID else {
                    return .none
                }

                state.isLoadingMore = true
                return fetch(
                    state: state,
                    page: state.currentPage + 1,
                    reset: false
                )
                .cancellable(id: CancelID.fetch, cancelInFlight: false)

            case ._debouncedSearchReady:
                guard !state.query.isEmpty else { return .none }
                return reload(state: &state, resetQuery: false)

            case let ._loadedPage(page, reset):
                state.currentPage = page.currentPage
                state.hasNextPage = page.hasNext
                state.layoutMetadata = page.meta
                state.errorMessage = nil
                state.isOffline = false
                state.isLoading = false
                state.isLoadingMore = false
                if reset {
                    state.items = page.data
                } else {
                    state.items.append(contentsOf: page.data)
                }
                return .none

            case let ._failed(message, isOffline):
                state.isLoading = false
                state.isLoadingMore = false
                state.isOffline = isOffline
                state.errorMessage = message
                return .none
            }
        }
    }

    private func reload(state: inout State, resetQuery: Bool) -> Effect<Action> {
        if resetQuery {
            state.query = ""
        }
        state.items = []
        state.layoutMetadata = nil
        state.currentPage = 1
        state.hasNextPage = true
        state.isLoadingMore = false
        state.isLoading = true
        state.isOffline = false
        state.errorMessage = nil

        return fetch(state: state, page: 1, reset: true)
            .cancellable(id: CancelID.fetch, cancelInFlight: true)
    }

    private func fetch(state: State, page: Int, reset: Bool) -> Effect<Action> {
        let tab = state.selectedTab
        let query = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        let locale = state.config.locale ?? locale

        return .run { [client, perPage] send in
            do {
                let pageResult: KlipyPage<KlipyContentItem>

                if query.isEmpty {
                    switch state.config.emptyQueryFeed {
                    case .trending:
                        pageResult = try await client.trendingContent(
                            kind: tab.mediaType,
                            page: page,
                            perPage: perPage,
                            locale: locale
                        )
                    case .recent:
                        pageResult = try await client.recentContent(
                            kind: tab.mediaType,
                            page: page,
                            perPage: perPage,
                            locale: locale,
                            adParams: nil
                        )
                    case .none:
                        pageResult = KlipyPage(
                            data: [],
                            currentPage: 1,
                            perPage: perPage,
                            hasNext: false,
                            meta: nil
                        )
                    }
                } else {
                    pageResult = try await client.searchContent(
                        kind: tab.mediaType,
                        query: query,
                        page: page,
                        perPage: perPage,
                        locale: locale
                    )
                }

                await send(._loadedPage(pageResult, reset: reset))
            } catch {
                let klipyError = (error as? KlipyError) ?? .transportError(underlying: error)
                await send(._failed(klipyError.description, isOffline: klipyError.isConnectivityError))
            }
        }
    }
}
