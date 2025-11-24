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
public final class KlipyPickerViewModel: ObservableObject, @unchecked Sendable {

    @Published public private(set) var items: [KlipyMedia] = []
    @Published public var query: String = ""
    @Published public var selectedTab: KlipyPickerMediaTab
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var lastError: KlipyError?

    private let client: KlipyClient

    private var currentPage: Int = 1
    private var hasNext: Bool = true

    public init(
        client: KlipyClient,
        initialTab: KlipyPickerMediaTab = .gifs,
    ) {
        self.client = client
        self.selectedTab = initialTab
    }

    // MARK: - Public API

    public func loadInitial() {
        items.removeAll()
        currentPage = 1
        hasNext = true
        lastError = nil

        Task {
            await loadPage(reset: true)
        }
    }

    public func didChangeTab(_ tab: KlipyPickerMediaTab) {
        selectedTab = tab
        loadInitial()
    }

    public func submitSearch() {
        Task {
            await loadPage(reset: true)
        }
    }

    public func loadMoreIfNeeded(currentItem: KlipyMedia) {
        guard let index = items.firstIndex(where: { $0.id == currentItem.id }) else { return }
        let thresholdIndex = items.index(items.endIndex, offsetBy: -6, limitedBy: items.startIndex) ?? items.startIndex

        if index >= thresholdIndex {
            Task { await loadPage(reset: false) }
        }
    }

    // MARK: - Internal loading logic

    private func loadPage(reset: Bool) async {
        if reset {
            items = []
            currentPage = 1
            hasNext = true
            lastError = nil
        }

        guard hasNext, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let mediaType = selectedTab.mediaType
            let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

            let page: KlipyPage<KlipyMedia>
            if trimmedQuery.isEmpty {
                page = try await client.trending(
                    kind: mediaType,
                    page: currentPage,
                    perPage: 24,
                    locale: nil,
                )
            } else {
                page = try await client.search(
                    kind: mediaType,
                    query: trimmedQuery,
                    page: currentPage,
                    perPage: 24,
                    locale: nil,
                )
            }

            items.append(contentsOf: page.data)
            hasNext = page.hasNext
            if page.hasNext { currentPage += 1 }

        } catch let klipyError as KlipyError {
            lastError = klipyError
        } catch {
            lastError = .transportError(underlying: error)
        }
    }

}
