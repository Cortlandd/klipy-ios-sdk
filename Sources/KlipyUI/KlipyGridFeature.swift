//
//  KlipyGridFeature.swift
//  KlipySDK
//
//  Created by Codex on 5/17/26.
//

import Foundation
import KlipyCore
import ComposableArchitecture

@Reducer
public struct KlipyGridFeature: Sendable {
    public init(
        client: KlipyClient,
        fallbackLocale: String = Locale.autoupdatingCurrent.identifier,
        perPage: Int = 24
    ) {
        self.client = client
        self.fallbackLocale = fallbackLocale
        self.perPage = perPage
    }

    let client: any KlipyMediaLoading
    let fallbackLocale: String
    let perPage: Int

    init(
        client: any KlipyMediaLoading,
        fallbackLocale: String = Locale.autoupdatingCurrent.identifier,
        perPage: Int = 24
    ) {
        self.client = client
        self.fallbackLocale = fallbackLocale
        self.perPage = perPage
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public var configuration: KlipyGridConfiguration
        public var content: KlipyGridContent
        public var items: [KlipyContentItem] = []
        public var layoutMetadata: KlipyPageMeta?
        public var isLoading = false
        public var isOffline = false
        public var errorMessage: String?
        public var currentPage = 1
        public var hasNextPage = true
        public var isLoadingMore = false
        public var hasLoadedOnce = false

        public init(
            content: KlipyGridContent,
            configuration: KlipyGridConfiguration = .init()
        ) {
            self.content = content
            self.configuration = configuration
        }
    }

    public enum Action: Sendable {
        case onAppear
        case setContent(KlipyGridContent)
        case retryTapped
        case loadMoreIfNeeded(String)

        case _loadedPage(KlipyPage<KlipyContentItem>, reset: Bool)
        case _failed(String, isOffline: Bool)
    }

    private enum CancelID: Hashable {
        case fetch
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoadedOnce else { return .none }
                state.hasLoadedOnce = true
                return reload(state: &state)

            case let .setContent(content):
                state.content = content
                return reload(state: &state)

            case .retryTapped:
                return reload(state: &state)

            case let .loadMoreIfNeeded(itemID):
                guard state.hasNextPage,
                      !state.isLoading,
                      !state.isLoadingMore,
                      state.items.last?.id == itemID else {
                    return .none
                }

                state.isLoadingMore = true
                return fetch(state: state, page: state.currentPage + 1, reset: false)
                    .cancellable(id: CancelID.fetch, cancelInFlight: false)

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

    private func reload(state: inout State) -> Effect<Action> {
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
        let content = state.content
        let locale = content.localeOverride ?? fallbackLocale

        return .run { [client, perPage] send in
            do {
                let pageResult: KlipyPage<KlipyContentItem>

                switch content {
                case let .trending(kind, _):
                    pageResult = try await client.trendingContent(
                        kind: kind,
                        page: page,
                        perPage: perPage,
                        locale: locale
                    )
                case let .recent(kind, _):
                    pageResult = try await client.recentContent(
                        kind: kind,
                        page: page,
                        perPage: perPage,
                        locale: locale,
                        adParams: nil
                    )
                case let .search(kind, query, _):
                    pageResult = try await client.searchContent(
                        kind: kind,
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
