//
//  KlipyPickerViewModelTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 4/10/26.
//

import XCTest
@testable import KlipyCore
@testable import KlipyUI

private actor MockKlipyMediaLoader: KlipyMediaLoading {
    enum Call: Equatable {
        case trending(kind: KlipyMediaType, page: Int?, perPage: Int?, locale: String?)
        case search(kind: KlipyMediaType, query: String, page: Int?, perPage: Int?, locale: String?)
    }

    private(set) var calls: [Call] = []
    var trendingResult: KlipyPage<KlipyMedia>
    var searchResult: KlipyPage<KlipyMedia>

    init(
        trendingResult: KlipyPage<KlipyMedia>,
        searchResult: KlipyPage<KlipyMedia>
    ) {
        self.trendingResult = trendingResult
        self.searchResult = searchResult
    }

    func trending(
        kind: KlipyMediaType,
        page: Int?,
        perPage: Int?,
        locale: String?
    ) async throws -> KlipyPage<KlipyMedia> {
        calls.append(.trending(kind: kind, page: page, perPage: perPage, locale: locale))
        return trendingResult
    }

    func search(
        kind: KlipyMediaType,
        query: String,
        page: Int?,
        perPage: Int?,
        locale: String?
    ) async throws -> KlipyPage<KlipyMedia> {
        calls.append(.search(kind: kind, query: query, page: page, perPage: perPage, locale: locale))
        return searchResult
    }
}

@MainActor
final class KlipyPickerViewModelTests: XCTestCase {

    func testLoadInitialFetchesTrendingItems() async {
        let loader = MockKlipyMediaLoader(
            trendingResult: .init(
                data: [KlipyMedia(id: "1", slug: "wave", type: .gif, title: "Wave")],
                currentPage: 1,
                perPage: 24,
                hasNext: true
            ),
            searchResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false)
        )

        let viewModel = KlipyPickerViewModel(
            client: loader,
            initialTab: .gifs,
            locale: "en-US",
            searchDebounceNanoseconds: 10_000_000
        )

        viewModel.loadInitial()
        await waitUntil { !viewModel.isLoading && !viewModel.items.isEmpty }

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items.first?.slug, "wave")

        let calls = await loader.calls
        XCTAssertEqual(calls, [.trending(kind: .gif, page: 1, perPage: 24, locale: "en-US")])
    }

    func testUpdateQueryTriggersDebouncedSearch() async {
        let loader = MockKlipyMediaLoader(
            trendingResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false),
            searchResult: .init(
                data: [KlipyMedia(id: "2", slug: "thumbs-up", type: .sticker, title: "Thumbs Up")],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            )
        )

        let viewModel = KlipyPickerViewModel(
            client: loader,
            initialTab: .stickers,
            locale: "en-US",
            searchDebounceNanoseconds: 10_000_000
        )

        viewModel.updateQuery("thumbs up")
        await waitUntil { !viewModel.isLoading && !viewModel.items.isEmpty }

        XCTAssertEqual(viewModel.items.first?.slug, "thumbs-up")

        let calls = await loader.calls
        XCTAssertEqual(calls, [.search(kind: .sticker, query: "thumbs up", page: 1, perPage: 24, locale: "en-US")])
    }

    func testChangingTabsLoadsTheNewMediaType() async {
        let loader = MockKlipyMediaLoader(
            trendingResult: .init(
                data: [KlipyMedia(id: "3", slug: "clip-time", type: .clip, title: "Clip Time")],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            ),
            searchResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false)
        )

        let viewModel = KlipyPickerViewModel(
            client: loader,
            initialTab: .gifs,
            locale: "en-US",
            searchDebounceNanoseconds: 10_000_000
        )

        viewModel.didChangeTab(.clips)
        await waitUntil { !viewModel.isLoading && !viewModel.items.isEmpty }

        XCTAssertEqual(viewModel.selectedTab, .clips)
        XCTAssertEqual(viewModel.items.first?.type, .clip)

        let calls = await loader.calls
        XCTAssertEqual(calls, [.trending(kind: .clip, page: 1, perPage: 24, locale: "en-US")])
    }

    func testChangingTabsCanLoadEmojiMedia() async {
        let loader = MockKlipyMediaLoader(
            trendingResult: .init(
                data: [KlipyMedia(id: "4", slug: "party-emoji", type: .emoji, title: "Party")],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            ),
            searchResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false)
        )

        let viewModel = KlipyPickerViewModel(
            client: loader,
            initialTab: .gifs,
            locale: "en-US",
            searchDebounceNanoseconds: 10_000_000
        )

        viewModel.didChangeTab(.emojis)
        await waitUntil { !viewModel.isLoading && !viewModel.items.isEmpty }

        XCTAssertEqual(viewModel.selectedTab, .emojis)
        XCTAssertEqual(viewModel.items.first?.type, .emoji)

        let calls = await loader.calls
        XCTAssertEqual(calls, [.trending(kind: .emoji, page: 1, perPage: 24, locale: "en-US")])
    }

    func testChangingTabsClearsQueryAndLoadsTrendingForTheNewMediaType() async {
        let loader = MockKlipyMediaLoader(
            trendingResult: .init(
                data: [KlipyMedia(id: "5", slug: "clip-party", type: .clip, title: "Clip Party")],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            ),
            searchResult: .init(
                data: [KlipyMedia(id: "6", slug: "search-result", type: .gif, title: "Search Result")],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            )
        )

        let viewModel = KlipyPickerViewModel(
            client: loader,
            initialTab: .gifs,
            locale: "en-US",
            searchDebounceNanoseconds: 10_000_000
        )

        viewModel.updateQuery("party")
        viewModel.didChangeTab(.clips)
        await waitUntil { !viewModel.isLoading && !viewModel.items.isEmpty }

        XCTAssertEqual(viewModel.selectedTab, .clips)
        XCTAssertEqual(viewModel.query, "")
        XCTAssertEqual(viewModel.items.first?.type, .clip)

        let calls = await loader.calls
        XCTAssertEqual(calls, [.trending(kind: .clip, page: 1, perPage: 24, locale: "en-US")])
    }

    func testInitialTabFallsBackToTheFirstAvailableTab() async {
        let loader = MockKlipyMediaLoader(
            trendingResult: .init(
                data: [KlipyMedia(id: "7", slug: "sticker-party", type: .sticker, title: "Sticker Party")],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            ),
            searchResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false)
        )

        let viewModel = KlipyPickerViewModel(
            client: loader,
            availableTabs: [.stickers, .clips],
            initialTab: .gifs,
            locale: "en-US",
            searchDebounceNanoseconds: 10_000_000
        )

        viewModel.loadInitial()
        await waitUntil { !viewModel.isLoading && !viewModel.items.isEmpty }

        XCTAssertEqual(viewModel.availableTabs, [.stickers, .clips])
        XCTAssertEqual(viewModel.selectedTab, .stickers)
        XCTAssertEqual(viewModel.items.first?.type, .sticker)

        let calls = await loader.calls
        XCTAssertEqual(calls, [.trending(kind: .sticker, page: 1, perPage: 24, locale: "en-US")])
    }

    func testUnavailableTabsAreIgnored() async {
        let loader = MockKlipyMediaLoader(
            trendingResult: .init(
                data: [KlipyMedia(id: "8", slug: "wave", type: .gif, title: "Wave")],
                currentPage: 1,
                perPage: 24,
                hasNext: false
            ),
            searchResult: .init(data: [], currentPage: 1, perPage: 24, hasNext: false)
        )

        let viewModel = KlipyPickerViewModel(
            client: loader,
            availableTabs: [.gifs, .stickers],
            initialTab: .gifs,
            locale: "en-US",
            searchDebounceNanoseconds: 10_000_000
        )

        viewModel.didChangeTab(.clips)
        await waitUntil { !viewModel.isLoading }

        XCTAssertEqual(viewModel.selectedTab, .gifs)

        let calls = await loader.calls
        XCTAssertEqual(calls, [])
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping @MainActor () -> Bool
    ) async {
        let endTime = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds

        while !condition() && DispatchTime.now().uptimeNanoseconds < endTime {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}
