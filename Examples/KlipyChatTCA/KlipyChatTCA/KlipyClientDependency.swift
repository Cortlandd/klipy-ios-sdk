//
//  KlipyClientDependency.swift
//  KlipyChatTCA
//
//  Provides a TCA dependency for a shared KlipyClient instance.
//

import ComposableArchitecture
import KlipyCore

private enum KlipyClientKey: DependencyKey {
    static let liveValue = KlipyClient(configuration: .init(apiKey: ""))
    static let previewValue = KlipyClient(configuration: .init(apiKey: ""))
    static let testValue = KlipyClient(configuration: .init(apiKey: ""))
}

extension DependencyValues {
    var klipyClient: KlipyClient {
        get { self[KlipyClientKey.self] }
        set { self[KlipyClientKey.self] = newValue }
    }
}
