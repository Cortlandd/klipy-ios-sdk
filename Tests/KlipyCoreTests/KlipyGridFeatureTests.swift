//
//  KlipyGridFeatureTests.swift
//  KlipySDK
//
//  Created by Codex on 5/17/26.
//

import XCTest
import ComposableArchitecture
@testable import KlipyCore
@testable import KlipyUI

private struct MockKlipyGridFeatureLoader: KlipyMediaLoading {
    var trendingResult: KlipyPage<KlipyContentItem>
    var recentResult: KlipyPage<KlipyContentItem>
    var searchResult: KlipyPage<KlipyContentItem>

    init(
        trendingResult: KlipyPage<KlipyContentItem>,
        recentResult: KlipyPage<KlipyContentItem>? = nil,
        searchResult: KlipyPage<KlipyContentItem>? = nil
    ) {
        self.trendingResult = trendingResult
        self.recentResult = recentResult ?? trendingResult
        self.searchResult = searchResult ?? trendingResult
    }

    func trendingContent(kind: KlipyMediaType, page: Int?, perPage: Int?, locale: String?) async throws -> KlipyPage<KlipyContentItem> {
        trendingResult
    }

    func recentContent(kind: KlipyMediaType, page: Int?, perPage: Int?, locale: String?, adParams: [String : String]?) async throws -> KlipyPage<KlipyContentItem> {
        recentResult
    }

    func searchContent(kind: KlipyMediaType, query: String, page: Int?, perPage: Int?, locale: String?) async throws -> KlipyPage<KlipyContentItem> {
        searchResult
    }
}

@MainActor
final class KlipyGridFeatureTests: XCTestCase {
    func testOnAppearLoadsConfiguredContent() async {
        let loader = MockKlipyGridFeatureLoader(
            trendingResult: .init(
                data: [.media(KlipyMedia(id: "1", slug: "wave", type: .gif, title: "Wave"))],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            )
        )

        let store = TestStore(
            initialState: KlipyGridFeature.State(content: .trending(kind: .gif, locale: "en-US"))
        ) {
            KlipyGridFeature(client: loader)
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
            $0.hasNextPage = false
            $0.layoutMetadata = loader.trendingResult.meta
            $0.isLoading = false
            $0.isLoadingMore = false
        }
    }

    func testSetContentCanSwitchToSearch() async {
        let loader = MockKlipyGridFeatureLoader(
            trendingResult: .init(
                data: [.media(KlipyMedia(id: "1", slug: "wave", type: .gif, title: "Wave"))],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            ),
            searchResult: .init(
                data: [.media(KlipyMedia(id: "2", slug: "search-hit", type: .gif, title: "Search Hit"))],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            )
        )

        let store = TestStore(
            initialState: KlipyGridFeature.State(content: .trending(kind: .gif, locale: "en-US"))
        ) {
            KlipyGridFeature(client: loader)
        }

        store.exhaustivity = .off

        await store.send(.setContent(.search(kind: .gif, query: "party", locale: "es-ES"))) {
            $0.content = .search(kind: .gif, query: "party", locale: "es-ES")
            $0.items = []
            $0.layoutMetadata = nil
            $0.currentPage = 1
            $0.hasNextPage = true
            $0.isLoading = true
            $0.isOffline = false
            $0.errorMessage = nil
        }

        await store.receive(._loadedPage(loader.searchResult, reset: true)) {
            $0.items = loader.searchResult.data
            $0.currentPage = 1
            $0.hasNextPage = false
            $0.layoutMetadata = loader.searchResult.meta
            $0.isLoading = false
            $0.isLoadingMore = false
        }
    }
}
