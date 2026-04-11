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
    public var isConnectivityError: Bool {
        switch self {
        case .transportError(let underlying):
            return Self.isConnectivityIssue(underlying)
        default:
            return false
        }
    }

    public static func isConnectivityIssue(_ error: Error) -> Bool {
        if let klipyError = error as? KlipyError {
            return klipyError.isConnectivityError
        }

        if let urlError = error as? URLError {
            return connectivityErrorCodes.contains(urlError.code)
        }

        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else {
            return false
        }

        let code = URLError.Code(rawValue: nsError.code)
        return connectivityErrorCodes.contains(code)
    }

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
            if Self.isConnectivityIssue(underlying) {
                return "No internet connection. Connect to the internet and try again."
            }
            return "Network/transport error: \(underlying.localizedDescription)"
        }
    }

    private static let connectivityErrorCodes: Set<URLError.Code> = [
        .notConnectedToInternet,
        .networkConnectionLost,
        .cannotConnectToHost,
        .cannotFindHost,
        .dnsLookupFailed,
        .dataNotAllowed,
        .internationalRoamingOff
    ]
}
