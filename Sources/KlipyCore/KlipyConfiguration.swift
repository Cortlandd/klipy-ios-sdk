//
//  KlipyConfiguration.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation

/// Configuration for the Klipy API client.
/// Use this to provide your API key and base URL.
public struct KlipyConfiguration: Sendable {
    /// Your Klipy API key. This is typically part of the path
    /// for all API requests, e.g. `/api/v1/{API_KEY}/gifs/search`.
    public var apiKey: String

    /// Base URL of the Klipy API.
    /// Default is `https://api.klipy.com`.
    public var baseURL: URL

    /// Optional default locale (e.g. "en-US") used when
    /// no locale is explicitly passed to client methods.
    public var defaultLocale: String?

    /// Optional default page size used when no `perPage`
    /// value is provided to client methods.
    public var defaultPerPage: Int?

    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.klipy.com")!,
        defaultLocale: String? = nil,
        defaultPerPage: Int? = nil
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.defaultLocale = defaultLocale
        self.defaultPerPage = defaultPerPage
    }
}
