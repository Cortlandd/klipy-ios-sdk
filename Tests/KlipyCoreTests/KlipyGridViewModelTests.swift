//
//  KlipyGridViewModelTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/16/26.
//

import XCTest
@testable import KlipyCore
@testable import KlipyUI

private actor MockKlipyGridLoader: KlipyMediaLoading {
    enum Call: Equatable {
        case trending(kind: KlipyMediaType, locale: String?)
        case recent(kind: KlipyMediaType, locale: String?)
        case search(kind: KlipyMediaType, query: String, locale: String?)
    }

    private(set) var calls: [Call] = []
    var trendingResult: KlipyPage<KlipyContentItem>
    var recentResult: KlipyPage<KlipyContentItem>
    var searchResult: KlipyPage<KlipyContentItem>

    init(
        trendingResult: KlipyPage<KlipyContentItem>,
        recentResult: KlipyPage<KlipyContentItem>,
        searchResult: KlipyPage<KlipyContentItem>
    ) {
        self.trendingResult = trendingResult
        self.recentResult = recentResult
        self.searchResult = searchResult
    }

    func trendingContent(kind: KlipyMediaType, page: Int?, perPage: Int?, locale: String?) async throws -> KlipyPage<KlipyContentItem> {
        calls.append(.trending(kind: kind, locale: locale))
        return trendingResult
    }

    func recentContent(kind: KlipyMediaType, page: Int?, perPage: Int?, locale: String?, adParams: [String : String]?) async throws -> KlipyPage<KlipyContentItem> {
        calls.append(.recent(kind: kind, locale: locale))
        return recentResult
    }

    func searchContent(kind: KlipyMediaType, query: String, page: Int?, perPage: Int?, locale: String?) async throws -> KlipyPage<KlipyContentItem> {
        calls.append(.search(kind: kind, query: query, locale: locale))
        return searchResult
    }
}

@MainActor
final class KlipyGridViewModelTests: XCTestCase {
    func testTrendingContentLoadsTrendingFeed() async {
        let loader = MockKlipyGridLoader(
            trendingResult: .init(
                data: [.media(KlipyMedia(id: "1", slug: "wave", type: .gif, title: "Wave"))],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            ),
            recentResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false),
            searchResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false)
        )

        let viewModel = KlipyGridViewModel(
            client: loader,
            content: .trending(kind: .gif, locale: "en-US")
        )

        viewModel.loadInitial()
        await waitUntil { !viewModel.isLoading && !viewModel.items.isEmpty }

        XCTAssertEqual(viewModel.items.first?.media?.slug, "wave")
        let calls = await loader.calls
        XCTAssertEqual(calls, [.trending(kind: .gif, locale: "en-US")])
    }

    func testRecentContentLoadsRecentFeed() async {
        let loader = MockKlipyGridLoader(
            trendingResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false),
            recentResult: .init(
                data: [.media(KlipyMedia(id: "2", slug: "recent", type: .sticker, title: "Recent"))],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            ),
            searchResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false)
        )

        let viewModel = KlipyGridViewModel(
            client: loader,
            content: .recent(kind: .sticker, locale: "fr-FR")
        )

        viewModel.loadInitial()
        await waitUntil { !viewModel.isLoading && !viewModel.items.isEmpty }

        XCTAssertEqual(viewModel.items.first?.media?.slug, "recent")
        let calls = await loader.calls
        XCTAssertEqual(calls, [.recent(kind: .sticker, locale: "fr-FR")])
    }

    func testSetContentCanSwitchToSearchResults() async {
        let loader = MockKlipyGridLoader(
            trendingResult: .init(
                data: [.media(KlipyMedia(id: "3", slug: "trending", type: .gif, title: "Trending"))],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            ),
            recentResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false),
            searchResult: .init(
                data: [.media(KlipyMedia(id: "4", slug: "search-hit", type: .gif, title: "Search Hit"))],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            )
        )

        let viewModel = KlipyGridViewModel(
            client: loader,
            content: .trending(kind: .gif, locale: "en-US")
        )

        viewModel.loadInitial()
        await waitUntil { !viewModel.isLoading && !viewModel.items.isEmpty }

        viewModel.setContent(.search(kind: .gif, query: "party", locale: "es-ES"))
        await waitUntil { !viewModel.isLoading && viewModel.items.first?.media?.slug == "search-hit" }

        let calls = await loader.calls
        XCTAssertEqual(
            calls,
            [
                .trending(kind: .gif, locale: "en-US"),
                .search(kind: .gif, query: "party", locale: "es-ES")
            ]
        )
    }
}
