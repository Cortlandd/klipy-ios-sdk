//
//  KlipyGridViewModel.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/16/26.
//

import Foundation
import SwiftUI
import KlipyCore

@MainActor
public final class KlipyGridViewModel: ObservableObject {
    @Published public private(set) var items: [KlipyContentItem] = []
    @Published public private(set) var layoutMetadata: KlipyPageMeta?
    @Published public private(set) var isLoading = false
    @Published public private(set) var lastError: KlipyError?

    public let configuration: KlipyGridConfiguration
    @Published public private(set) var content: KlipyGridContent

    private let client: any KlipyMediaLoading
    private let fallbackLocale: String
    private let perPage: Int
    private var currentPage = 1
    private var hasNextPage = true
    private var isLoadingMore = false
    private var activeLoadTask: Task<Void, Never>?

    public init(
        client: any KlipyMediaLoading,
        content: KlipyGridContent,
        configuration: KlipyGridConfiguration = .init(),
        fallbackLocale: String = Locale.autoupdatingCurrent.identifier,
        perPage: Int = 24
    ) {
        self.client = client
        self.content = content
        self.configuration = configuration
        self.fallbackLocale = fallbackLocale
        self.perPage = perPage
    }

    deinit {
        activeLoadTask?.cancel()
    }

    public func loadInitial() {
        currentPage = 1
        hasNextPage = true
        isLoadingMore = false
        items = []
        layoutMetadata = nil
        lastError = nil

        loadPage(page: 1, reset: true)
    }

    public func setContent(_ content: KlipyGridContent) {
        self.content = content
        loadInitial()
    }

    public func loadMoreIfNeeded(currentItem: KlipyContentItem) {
        guard hasNextPage,
              !isLoading,
              !isLoadingMore,
              let last = items.last,
              last.id == currentItem.id else {
            return
        }

        isLoadingMore = true
        loadPage(page: currentPage + 1, reset: false)
    }

    private func loadPage(page: Int, reset: Bool) {
        activeLoadTask?.cancel()
        isLoading = true

        let content = content
        let locale = content.localeOverride ?? fallbackLocale

        activeLoadTask = Task { [weak self] in
            guard let self else { return }

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
