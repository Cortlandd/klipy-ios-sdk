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
    @Published public private(set) var items: [KlipyMedia] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var lastError: KlipyError?

    @Published public var selectedTab: KlipyPickerMediaTab
    @Published public var query: String = ""

    private let client: KlipyClient

    // Pagination state
    private var currentPage: Int = 1
    private var hasNextPage: Bool = true
    private let perPage: Int = 24
    private var isLoadingMore: Bool = false

    public init(
        client: KlipyClient,
        initialTab: KlipyPickerMediaTab = .gifs
    ) {
        self.client = client
        self.selectedTab = initialTab
    }

    // MARK: - Public API

    public func loadInitial() {
        currentPage = 1
        hasNextPage = true
        items = []
        lastError = nil

        Task {
            await loadPage(page: 1, reset: true)
        }
    }

    public func didChangeTab(_ tab: KlipyPickerMediaTab) {
        selectedTab = tab
        loadInitial()
    }

    public func submitSearch() {
        loadInitial()
    }

    /// Called by the view when a cell appears.
    public func loadMoreIfNeeded(currentItem: KlipyMedia) {
        guard hasNextPage,
              !isLoadingMore,
              !isLoading,
              let last = items.last,
              last.id == currentItem.id else {
            return
        }

        let nextPage = currentPage + 1
        isLoadingMore = true

        Task {
            await loadPage(page: nextPage, reset: false)
            isLoadingMore = false
        }
    }

    // MARK: - Internal page loader

    private func loadPage(page: Int, reset: Bool) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let kind = selectedTab.mediaType

            let pageResult: KlipyPage<KlipyMedia>

            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // trending
                pageResult = try await client.trending(
                    kind: kind,
                    page: page,
                    perPage: perPage,
                    locale: "en-US",
                )
            } else {
                // search
                pageResult = try await client.search(
                    kind: kind,
                    query: query,
                    page: page,
                    perPage: perPage,
                    locale: "en-US",
                )
            }

            currentPage = pageResult.currentPage
            hasNextPage = pageResult.hasNext

            if reset {
                items = pageResult.data
            } else {
                items.append(contentsOf: pageResult.data)
            }

        } catch {
            lastError = (error as? KlipyError) ?? .transportError(underlying: error)
        }
    }
}
