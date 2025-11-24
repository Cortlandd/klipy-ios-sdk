//
//  KlipyClient.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation

/// Core Klipy API client using `URLSession` and `async/await`.
public final class KlipyClient: @unchecked Sendable {

    public let configuration: KlipyConfiguration
    private let urlSession: URLSession

    public init(
        configuration: KlipyConfiguration,
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    /// Creates a client with default base URL.
    public static func live(apiKey: String) -> KlipyClient {
        KlipyClient(
            configuration: KlipyConfiguration(apiKey: apiKey),
            urlSession: .shared
        )
    }
}

// MARK: - Core request helpers

private extension KlipyClient {
    func buildURL(
        pathComponents: [String],
        queryItems: [String: String] = [:]
    ) throws -> URL {
        var url = configuration.baseURL
        for component in pathComponents {
            url.appendPathComponent(component)
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }

        guard let finalURL = components?.url else {
            throw KlipyError.invalidURL
        }
        return finalURL
    }

    func request<T: Decodable & Sendable>(
        pathComponents: [String],
        queryItems: [String: String] = [:],
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        let url = try buildURL(pathComponents: pathComponents, queryItems: queryItems)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.httpBody = body

        do {
            let (data, response) = try await urlSession.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw KlipyError.httpError(statusCode: -1, body: data)
            }
            guard (200..<300).contains(http.statusCode) else {
                throw KlipyError.httpError(statusCode: http.statusCode, body: data)
            }

            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                throw KlipyError.decodingError(underlying: error)
            }
        } catch {
            throw KlipyError.transportError(underlying: error)
        }
    }
}

// MARK: - Generic media endpoints (by type)

public extension KlipyClient {

    /// Trending items for a given media type.
    func trending(
        kind: KlipyMediaType,
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil,
        customerId: String
    ) async throws -> KlipyPage<KlipyMedia> {
        var params: [String: String] = [:]
        if let page = page { params["page"] = String(page) }
        if let per = perPage ?? configuration.defaultPerPage {
            params["per_page"] = String(per)
        }
        if let loc = locale ?? configuration.defaultLocale {
            params["locale"] = loc
        }
        
        params["customer_id"] = customerId

        let envelope: KlipyEnvelope<KlipyPage<KlipyMedia>> = try await request(
            pathComponents: ["api", "v1", configuration.apiKey, kind.pathSegment, "trending"],
            queryItems: params
        )
        return envelope.data
    }

    /// Search API for a given media type.
    func search(
        kind: KlipyMediaType,
        query: String,
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil,
        customerId: String? = nil
    ) async throws -> KlipyPage<KlipyMedia> {
        var params: [String: String] = ["q": query]
        if let page = page { params["page"] = String(page) }
        if let per = perPage ?? configuration.defaultPerPage {
            params["per_page"] = String(per)
        }
        if let loc = locale ?? configuration.defaultLocale {
            params["locale"] = loc
        }
        if let customerId = customerId {
            params["customer_id"] = customerId
        }

        let envelope: KlipyEnvelope<KlipyPage<KlipyMedia>> = try await request(
            pathComponents: ["api", "v1", configuration.apiKey, kind.pathSegment, "search"],
            queryItems: params
        )
        return envelope.data
    }

    /// Recent items per user for a given media type.
    func recent(
        kind: KlipyMediaType,
        customerId: String,
        page: Int? = nil,
        perPage: Int? = nil,
        locale: String? = nil,
        adParams: [String: String]? = nil
    ) async throws -> KlipyPage<KlipyMedia> {
        var params: [String: String] = [:]
        if let page = page { params["page"] = String(page) }
        if let per = perPage ?? configuration.defaultPerPage {
            params["per_page"] = String(per)
        }
        if let loc = locale ?? configuration.defaultLocale {
            params["locale"] = loc
        }
        if let adParams = adParams {
            for (k, v) in adParams {
                params[k] = v
            }
        }

        let envelope: KlipyEnvelope<KlipyPage<KlipyMedia>> = try await request(
            pathComponents: ["api", "v1", configuration.apiKey, kind.pathSegment, "recent", customerId],
            queryItems: params
        )
        return envelope.data
    }


    /// {kind} - Items API: fetch items by ID/slug list.
    ///
    /// Exact parameter name (e.g. `slugs` or `ids`) should be aligned with docs.

    func items(
        kind: KlipyMediaType,
        ids: String?,
        slugs: String?,
    ) async throws -> [KlipyMedia] {
        var params: [String: String] = [:]

        if let ids, !ids.isEmpty {
            params["ids"] = ids
        }
        
        if let slugs, !slugs.isEmpty {
            params["slugs"] = slugs
        }
        
        // Require exactly one of ids or slugs.
        if params.isEmpty || params.count > 1 {
            throw KlipyError.invalidParameters(message: "Provide either ids OR slugs (comma-separated), not both.")
        }

        let envelope: KlipyEnvelope<KlipyMediaListPayload> = try await request(
            pathComponents: ["api", "v1", configuration.apiKey, kind.pathSegment, "items"],
            queryItems: params
        )

        return envelope.data.data
    }

    /// Single item by slug/ID.
    func item(
        kind: KlipyMediaType,
        slugOrId: String
    ) async throws -> KlipyMedia {
        let envelope: KlipyEnvelope<KlipyMedia> = try await request(
            pathComponents: ["api", "v1", configuration.apiKey, kind.pathSegment, slugOrId]
        )
        return envelope.data
    }


    /// Categories for a given media type.
    func categories(
        kind: KlipyMediaType,
        locale: String? = nil
    ) async throws -> [KlipyCategory] {
        var params: [String: String] = [:]
        if let loc = locale ?? configuration.defaultLocale {
            params["locale"] = loc
        }

        // The API returns:
        // { "result": true, "data": { "locale": "...", "categories": [ ... ] } }
        let envelope: KlipyEnvelope<KlipyCategoryPayload> = try await request(
            pathComponents: ["api", "v1", configuration.apiKey, kind.pathSegment, "categories"],
            queryItems: params
        )

        return envelope.data.categories
    }

    /// Hide an item from a user's Recent list.
    ///
    /// DELETE /api/v1/{app_key}/{kind}/recent/{customer_id}/{slug}
    func hideFromRecent(
        kind: KlipyMediaType,
        customerId: String,
        slug: String
    ) async throws {
        _ = try await request(
            pathComponents: [
                "api", "v1", configuration.apiKey,
                kind.pathSegment, "recent", customerId, slug
            ],
            method: "DELETE"
        ) as EmptyResponse
    }


    /// Share trigger: notify Klipy that a user shared an item.
    ///
    /// POST /api/v1/{app_key}/{kind}/share/{slug}
    /// Body: { "customer_id": "...", "q": "search string that led to this share" }
    func triggerShare(
        kind: KlipyMediaType,
        slug: String,
        customerId: String,
        searchQuery: String
    ) async throws {
        struct Payload: Codable {
            let customer_id: String
            let q: String
        }

        let payload = Payload(customer_id: customerId, q: searchQuery)
        let body = try JSONEncoder().encode(payload)

        _ = try await request(
            pathComponents: [
                "api", "v1", configuration.apiKey,
                kind.pathSegment, "share", slug
            ],
            method: "POST",
            body: body
        ) as EmptyResponse
    }

    /// Report API: flag an item as inappropriate / problematic.
    ///
    /// POST /api/v1/{app_key}/{kind}/report/{slug}
    /// Body: { "customer_id"?: "...", "reason": "..." }
    func report(
        kind: KlipyMediaType,
        slug: String,
        customerId: String? = nil,
        reason: String
    ) async throws {
        struct Payload: Codable {
            let customer_id: String?
            let reason: String
        }

        let payload = Payload(customer_id: customerId, reason: reason)
        let body = try JSONEncoder().encode(payload)

        _ = try await request(
            pathComponents: [
                "api", "v1", configuration.apiKey, kind.pathSegment, "report", slug
            ],
            method: "POST",
            body: body
        ) as EmptyResponse
    }

    /// Search Suggestions API.
    func searchSuggestions(
        limit: Int = 10,
        query: String
    ) async throws -> [String] {
        var params: [String: String] = [:]
        
        params["limit"] = limit.description

        let envelope: KlipyEnvelope<[String]> = try await request(
            pathComponents: ["api", "v1", configuration.apiKey, "search-suggestions", query],
            queryItems: params
        )
        return envelope.data
    }
    
    func autocomplete(
        limit: Int = 10,
        q: String
    ) async throws -> [String] {
        let path = [
            "api", "v1", configuration.apiKey,
            "search-autocomplete", q
        ]
        let params = ["limit": limit.description]

        do {
            let envelope: KlipyEnvelope<[String]> = try await request(
                pathComponents: path,
                queryItems: params
            )
            return envelope.data
        } catch let KlipyError.transportError(underlying: underlying) {
            // request() wrapped a decoding error inside transportError
            if let kerr = underlying as? KlipyError,
               case .decodingError = kerr {
                // Bad / empty JSON → treat as "no suggestions"
                return []
            }
            // Other underlying transport errors should still bubble up
            throw KlipyError.transportError(underlying: underlying)
        /// Special case to handle Empty JSON
        } catch KlipyError.decodingError {
            // In case request() ever surfaces decodingError directly
            return []
        }
    }

}

/// Marker type for endpoints that return an empty response.
private struct EmptyResponse: Codable {}
