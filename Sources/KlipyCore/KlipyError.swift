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
