//
//  KlipyPickerViewModel.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/24/25.
//

import Foundation
import SwiftUI
import KlipyCore

@MainActor
public final class KlipyPickerViewModel: ObservableObject {
    @Published public private(set) var items: [KlipyContentItem] = []
    @Published public private(set) var layoutMetadata: KlipyPageMeta?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var lastError: KlipyError?

    public let config: KlipyPickerConfig
    @Published public var selectedTab: KlipyPickerMediaTab
    @Published public var query: String = ""

    private let client: any KlipyMediaLoading
    private let locale: String
    private let perPage: Int
    private let searchDebounceNanoseconds: UInt64

    // Pagination state
    private var currentPage: Int = 1
    private var hasNextPage: Bool = true
    private var isLoadingMore: Bool = false
    private var activeLoadTask: Task<Void, Never>?
    private var debouncedSearchTask: Task<Void, Never>?

    public init(
        client: any KlipyMediaLoading,
        config: KlipyPickerConfig = .init(),
        locale: String = Locale.autoupdatingCurrent.identifier,
        perPage: Int = 24,
        searchDebounceNanoseconds: UInt64 = 350_000_000
    ) {
        self.client = client
        let resolvedTabs = config.mediaTabs.isEmpty ? KlipyPickerMediaTab.allCases : config.mediaTabs
        self.config = KlipyPickerConfig(
            mediaTabs: resolvedTabs,
            columns: config.columns,
            showRecents: config.showRecents,
            showTrending: config.showTrending,
            initialTab: resolvedTabs.contains(config.initialTab) ? config.initialTab : resolvedTabs[0]
        )
        self.selectedTab = self.config.initialTab
        self.locale = locale
        self.perPage = perPage
        self.searchDebounceNanoseconds = searchDebounceNanoseconds
    }

    public convenience init(
        client: any KlipyMediaLoading,
        availableTabs: [KlipyPickerMediaTab] = KlipyPickerMediaTab.allCases,
        initialTab: KlipyPickerMediaTab = .gifs,
        locale: String = Locale.autoupdatingCurrent.identifier,
        perPage: Int = 24,
        searchDebounceNanoseconds: UInt64 = 350_000_000
    ) {
        self.init(
            client: client,
            config: KlipyPickerConfig(mediaTabs: availableTabs, initialTab: initialTab),
            locale: locale,
            perPage: perPage,
            searchDebounceNanoseconds: searchDebounceNanoseconds
        )
    }

    deinit {
        activeLoadTask?.cancel()
        debouncedSearchTask?.cancel()
    }

    // MARK: - Public API

    public func loadInitial() {
        activeLoadTask?.cancel()
        currentPage = 1
        hasNextPage = true
        items = []
        layoutMetadata = nil
        lastError = nil

        loadPage(page: 1, reset: true)
    }

    public func didChangeTab(_ tab: KlipyPickerMediaTab) {
        guard config.mediaTabs.contains(tab) else { return }
        debouncedSearchTask?.cancel()
        selectedTab = tab
        query = ""
        loadInitial()
    }

    public func updateQuery(_ value: String) {
        query = value
        debouncedSearchTask?.cancel()

        let trimmedQuery = value.trimmingCharacters(in: .whitespacesAndNewlines)

        debouncedSearchTask = Task { [weak self] in
            guard let self else { return }

            if trimmedQuery.isEmpty {
                await MainActor.run {
                    self.loadInitial()
                }
                return
            }

            do {
                try await Task.sleep(nanoseconds: searchDebounceNanoseconds)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.loadInitial()
            }
        }
    }

    public func submitSearch() {
        debouncedSearchTask?.cancel()
        loadInitial()
    }

    /// Called by the view when a cell appears.
    public func loadMoreIfNeeded(currentItem: KlipyContentItem) {
        guard hasNextPage,
              !isLoadingMore,
              !isLoading,
              let last = items.last,
              last.id == currentItem.id else {
            return
        }

        let nextPage = currentPage + 1
        isLoadingMore = true

        loadPage(page: nextPage, reset: false)
    }

    // MARK: - Internal page loader

    private func loadPage(page: Int, reset: Bool) {
        activeLoadTask?.cancel()
        isLoading = true
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedTab = selectedTab
        let locale = locale

        activeLoadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let pageResult: KlipyPage<KlipyContentItem>

                if trimmedQuery.isEmpty {
                    switch config.emptyQueryFeed {
                    case .trending:
                        pageResult = try await client.trendingContent(
                            kind: selectedTab.mediaType,
                            page: page,
                            perPage: perPage,
                            locale: locale
                        )
                    case .recent:
                        pageResult = try await client.recentContent(
                            kind: selectedTab.mediaType,
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
                        kind: selectedTab.mediaType,
                        query: trimmedQuery,
                        page: page,
                        perPage: perPage,
                        locale: locale
                    )
                }

                guard !Task.isCancelled else { return }

                currentPage = pageResult.currentPage
                hasNextPage = pageResult.hasNext
                layoutMetadata = pageResult.meta
                lastError = nil

                if reset {
                    items = pageResult.data
                } else {
                    items.append(contentsOf: pageResult.data)
                }
            } catch {
                guard !Task.isCancelled else { return }
                lastError = (error as? KlipyError) ?? .transportError(underlying: error)
            }
            isLoading = false
            isLoadingMore = false
        }
    }
}
