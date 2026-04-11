import XCTest
@testable import KlipyCore

enum KlipyIntegrationTestSupport {
    static let apiKeyEnvironmentVariable = "KLIPY_LIVE_API_KEY"

    static func makeLiveClient(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> KlipyClient {
        guard let apiKey = ProcessInfo.processInfo.environment[apiKeyEnvironmentVariable]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              apiKey.isEmpty == false
        else {
            throw XCTSkip("Set \(apiKeyEnvironmentVariable) to run live Klipy integration tests.")
        }

        return KlipyClient.live(apiKey: apiKey)
    }
}
