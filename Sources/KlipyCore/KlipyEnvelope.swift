//
//  KlipyEnvelope.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

public struct KlipyEnvelope<T: Decodable & Sendable>: Decodable, Sendable {
    public let result: Bool
    public let data: T
}
