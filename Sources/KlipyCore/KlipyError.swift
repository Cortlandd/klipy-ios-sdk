//
//  KlipyError.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import Foundation

/// Errors that can occur when calling the Klipy API.
public enum KlipyError: Error, Sendable {
    case invalidURL
    case httpError(statusCode: Int, body: Data?)
    case decodingError(underlying: Error)
    case transportError(underlying: Error)
    case invalidParameters(message: String)
}

extension KlipyError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidURL:
            return "The Klipy URL could not be constructed."
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        case let .httpError(statusCode, body):
            let bodySnippet: String
            if let body, let s = String(data: body, encoding: .utf8), !s.isEmpty {
                bodySnippet = " body=\(s)"
            } else {
                bodySnippet = ""
            }
            return "Klipy: HTTP \(statusCode)\(bodySnippet)"
        case .decodingError(let underlying):
            return "Failed to decode Klipy response: \(underlying.localizedDescription)"
        case .transportError(let underlying):
            return "Network/transport error: \(underlying.localizedDescription)"
        }
    }
}
