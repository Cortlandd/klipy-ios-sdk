//
//  KlipyTrayFeatureTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 4/10/26.
//

import XCTest
import ComposableArchitecture
@testable import KlipyCore
@testable import KlipyTray
@testable import KlipyUI

private struct MockKlipyTrayLoader: KlipyTrayLoading {
    var configuration: KlipyConfiguration
    var categoriesResult: [KlipyCategory] = []
    var trendingResult: KlipyPage<KlipyMedia>
    var recentResult: KlipyPage<KlipyMedia>
    var searchResult: KlipyPage<KlipyMedia>
    var categoriesError: Error?
    var trendingError: Error?
    var recentError: Error?
    var searchError: Error?

    init(
        configuration: KlipyConfiguration = .init(apiKey: "demo-key"),
        categoriesResult: [KlipyCategory] = [],
        trendingResult: KlipyPage<KlipyMedia>,
        recentResult: KlipyPage<KlipyMedia>? = nil,
        searchResult: KlipyPage<KlipyMedia>? = nil,
        categoriesError: Error? = nil,
        trendingError: Error? = nil,
        recentError: Error? = nil,
        searchError: Error? = nil
    ) {
        self.configuration = configuration
        self.categoriesResult = categoriesResult
        self.trendingResult = trendingResult
        self.recentResult = recentResult ?? trendingResult
        self.searchResult = searchResult ?? trendingResult
        self.categoriesError = categoriesError
        self.trendingError = trendingError
        self.recentError = recentError
        self.searchError = searchError
    }

    func categories(kind: KlipyMediaType, locale: String?) async throws -> [KlipyCategory] {
        if let categoriesError {
            throw categoriesError
        }
        categoriesResult
    }

    func trending(
        kind: KlipyMediaType,
        page: Int?,
        perPage: Int?,
        locale: String?
    ) async throws -> KlipyPage<KlipyMedia> {
        if let trendingError {
            throw trendingError
        }
        trendingResult
    }

    func recent(
        kind: KlipyMediaType,
        page: Int?,
        perPage: Int?,
        locale: String?,
        adParams: [String : String]?
    ) async throws -> KlipyPage<KlipyMedia> {
        if let recentError {
            throw recentError
        }
        recentResult
    }

    func search(
        kind: KlipyMediaType,
        query: String,
        page: Int?,
        perPage: Int?,
        locale: String?
    ) async throws -> KlipyPage<KlipyMedia> {
        if let searchError {
            throw searchError
        }
        searchResult
    }
}

@MainActor
final class KlipyTrayFeatureTests: XCTestCase {

    func testOnAppearLoadsTheConfiguredInitialTab() async {
        let loader = MockKlipyTrayLoader(
            trendingResult: .init(
                data: [KlipyMedia(id: "1", slug: "stickers-first", type: .sticker, title: "Sticker")],
                currentPage: 1,
                perPage: 24,
                hasNext: true
            )
        )

        let store = TestStore(
            initialState: KlipyTrayFeature.State(
                config: .init(
                    mediaTabs: [.gifs, .stickers],
                    initialTab: .stickers,
                    showCategories: false
                )
            )
        ) {
            KlipyTrayFeature(client: loader)
        }

        await store.send(.onAppear) {
            $0.mediaTabs = [.gifs, .stickers]
            $0.chosenTab = .stickers
            $0.isLoading = true
        }
        await store.receive(.tabSelected(.stickers)) {
            $0.chosenTab = .stickers
            $0.mediaItems = []
            $0.currentPage = 1
            $0.hasNext = true
            $0.isFetchingNextPage = false
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(._loadedCategories([])) {
            $0.categories = []
        }
        await store.receive(._loadedPage(loader.trendingResult, reset: true)) {
            $0.mediaItems = loader.trendingResult.data
            $0.currentPage = 1
            $0.hasNext = true
            $0.isLoading = false
            $0.isFetchingNextPage = false
        }
    }

    func testClearingSearchInputReloadsTheDefaultFeed() async {
        let loader = MockKlipyTrayLoader(
            trendingResult: .init(
                data: [KlipyMedia(id: "2", slug: "back-to-trending", type: .gif, title: "Trending")],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            )
        )

        let store = TestStore(
            initialState: {
                var state = KlipyTrayFeature.State(config: .init(showCategories: false))
                state.mediaTabs = [.gifs]
                state.chosenTab = .gifs
                state.lastSearchedInput = "hello"
                state.searchInput = "hello"
                state.mediaItems = [KlipyMedia(id: "existing", slug: "existing", type: .gif, title: "Existing")]
                return state
            }()
        ) {
            KlipyTrayFeature(client: loader)
        }

        store.exhaustivity = .off

        await store.send(.searchInputChanged("   ")) {
            $0.searchInput = ""
            $0.mediaItems = []
            $0.currentPage = 1
            $0.hasNext = true
            $0.isFetchingNextPage = false
            $0.isLoading = true
            $0.errorMessage = nil
            $0.lastSearchedInput = nil
        }

        await store.receive(._loadedPage(loader.trendingResult, reset: true)) {
            $0.mediaItems = loader.trendingResult.data
            $0.currentPage = 1
            $0.hasNext = false
            $0.isLoading = false
            $0.isFetchingNextPage = false
        }
    }

    func testOfflineFailuresSetTheTrayOfflineState() async {
        let loader = MockKlipyTrayLoader(
            trendingResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false),
            trendingError: URLError(.notConnectedToInternet)
        )

        let store = TestStore(
            initialState: KlipyTrayFeature.State(
                config: .init(showCategories: false)
            )
        ) {
            KlipyTrayFeature(client: loader)
        }

        await store.send(.onAppear) {
            $0.mediaTabs = KlipyPickerMediaTab.allCases
            $0.chosenTab = .gifs
            $0.isLoading = true
        }
        await store.receive(.tabSelected(.gifs)) {
            $0.chosenTab = .gifs
            $0.mediaItems = []
            $0.currentPage = 1
            $0.hasNext = true
            $0.isFetchingNextPage = false
            $0.isLoading = true
            $0.isOffline = false
            $0.errorMessage = nil
        }
        await store.receive(._loadedCategories([])) {
            $0.categories = []
        }
        await store.receive(._failed("No internet connection. Connect to the internet and try again.", isOffline: true)) {
            $0.isLoading = false
            $0.isFetchingNextPage = false
            $0.isOffline = true
            $0.errorMessage = "No internet connection. Connect to the internet and try again."
        }
    }
}
