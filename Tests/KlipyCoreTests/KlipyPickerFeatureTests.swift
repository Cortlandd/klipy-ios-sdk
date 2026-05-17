//
//  KlipyPickerFeatureTests.swift
//  KlipySDK
//
//  Created by Codex on 5/17/26.
//

import XCTest
import ComposableArchitecture
@testable import KlipyCore
@testable import KlipyUI

private struct MockKlipyPickerLoader: KlipyMediaLoading {
    var trendingResult: KlipyPage<KlipyContentItem>
    var recentResult: KlipyPage<KlipyContentItem>
    var searchResult: KlipyPage<KlipyContentItem>
    var trendingError: Error?
    var recentError: Error?
    var searchError: Error?

    init(
        trendingResult: KlipyPage<KlipyContentItem>,
        recentResult: KlipyPage<KlipyContentItem>? = nil,
        searchResult: KlipyPage<KlipyContentItem>? = nil,
        trendingError: Error? = nil,
        recentError: Error? = nil,
        searchError: Error? = nil
    ) {
        self.trendingResult = trendingResult
        self.recentResult = recentResult ?? trendingResult
        self.searchResult = searchResult ?? trendingResult
        self.trendingError = trendingError
        self.recentError = recentError
        self.searchError = searchError
    }

    func trendingContent(kind: KlipyMediaType, page: Int?, perPage: Int?, locale: String?) async throws -> KlipyPage<KlipyContentItem> {
        if let trendingError { throw trendingError }
        return trendingResult
    }

    func recentContent(kind: KlipyMediaType, page: Int?, perPage: Int?, locale: String?, adParams: [String : String]?) async throws -> KlipyPage<KlipyContentItem> {
        if let recentError { throw recentError }
        return recentResult
    }

    func searchContent(kind: KlipyMediaType, query: String, page: Int?, perPage: Int?, locale: String?) async throws -> KlipyPage<KlipyContentItem> {
        if let searchError { throw searchError }
        return searchResult
    }
}

@MainActor
final class KlipyPickerFeatureTests: XCTestCase {
    func testOnAppearLoadsConfiguredInitialTab() async {
        let loader = MockKlipyPickerLoader(
            trendingResult: .init(
                data: [.media(KlipyMedia(id: "1", slug: "wave", type: .gif, title: "Wave"))],
                currentPage: 1,
                perPage: 24,
                hasNext: true
            )
        )

        let store = TestStore(
            initialState: KlipyPickerFeature.State(
                config: .init(
                    mediaTabs: [.gifs, .stickers],
                    initialTab: .stickers
                )
            )
        ) {
            KlipyPickerFeature(client: loader)
        }

        await store.send(.onAppear) {
            $0.hasLoadedOnce = true
            $0.items = []
            $0.layoutMetadata = nil
            $0.currentPage = 1
            $0.hasNextPage = true
            $0.isLoading = true
            $0.isOffline = false
            $0.errorMessage = nil
        }
        await store.receive(._loadedPage(loader.trendingResult, reset: true)) {
            $0.items = loader.trendingResult.data
            $0.currentPage = 1
            $0.hasNextPage = true
            $0.layoutMetadata = loader.trendingResult.meta
            $0.isLoading = false
            $0.isLoadingMore = false
        }
    }

    func testTabSelectionClearsSearchAndLoadsNewFeed() async {
        let loader = MockKlipyPickerLoader(
            trendingResult: .init(
                data: [.media(KlipyMedia(id: "2", slug: "clip-time", type: .clip, title: "Clip"))],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            )
        )

        let store = TestStore(
            initialState: {
                var state = KlipyPickerFeature.State(config: .init(initialTab: .gifs))
                state.query = "hello"
                state.items = [.media(KlipyMedia(id: "old", slug: "old", type: .gif, title: "Old"))]
                return state
            }()
        ) {
            KlipyPickerFeature(client: loader)
        }

        await store.send(.tabSelected(.clips)) {
            $0.selectedTab = .clips
            $0.query = ""
            $0.items = []
            $0.layoutMetadata = nil
            $0.currentPage = 1
            $0.hasNextPage = true
            $0.isLoadingMore = false
            $0.isLoading = true
            $0.isOffline = false
            $0.errorMessage = nil
        }
        await store.receive(._loadedPage(loader.trendingResult, reset: true)) {
            $0.items = loader.trendingResult.data
            $0.currentPage = 1
            $0.hasNextPage = false
            $0.layoutMetadata = loader.trendingResult.meta
            $0.isLoading = false
            $0.isLoadingMore = false
        }
    }

    func testOfflineFailuresSetPickerOfflineState() async {
        let loader = MockKlipyPickerLoader(
            trendingResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false),
            trendingError: URLError(.notConnectedToInternet)
        )

        let store = TestStore(
            initialState: KlipyPickerFeature.State(config: .init())
        ) {
            KlipyPickerFeature(client: loader)
        }

        await store.send(.onAppear) {
            $0.hasLoadedOnce = true
            $0.items = []
            $0.layoutMetadata = nil
            $0.currentPage = 1
            $0.hasNextPage = true
            $0.isLoading = true
            $0.isOffline = false
            $0.errorMessage = nil
        }
        await store.receive(._failed("No internet connection. Connect to the internet and try again.", isOffline: true)) {
            $0.isLoading = false
            $0.isLoadingMore = false
            $0.isOffline = true
            $0.errorMessage = "No internet connection. Connect to the internet and try again."
        }
    }
}
