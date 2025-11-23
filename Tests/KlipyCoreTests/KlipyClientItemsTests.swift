//
//  KlipyClientItemsTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/23/25.
//

import XCTest
@testable import KlipyCore

/// Tests the parameter validation in `KlipyClient.items(kind:ids:slugs:)`.
///
/// These are pure unit tests: they exercise only the preflight checks
/// and never actually hit the network.
final class KlipyClientItemsTests: XCTestCase {
    
    /// Creates a client whose configuration will never actually be used
    /// to perform network I/O in these tests.
    private func makeDummyClient() -> KlipyClient {
        let config = KlipyConfiguration(
            apiKey: "test-api-key",
            baseURL: URL(string: "https://example.com")!,
            defaultLocale: nil,
            defaultPerPage: nil
        )
        return KlipyClient(configuration: config, urlSession: .init(configuration: .ephemeral))
    }
    
    func testItemsThrowsWhenBothIdsAndSlugsAreProvided() async throws {
        // Given
        let client = makeDummyClient()
        
        do {
            _ = try await client.items(
                kind: .gif,
                ids: "1,2,3",
                slugs: "foo,bar"
            )
            XCTFail("Expected items(kind:ids:slugs:) to throw for both ids and slugs")
        } catch let error as KlipyError {
            guard case .invalidParameters(let message) = error else {
                XCTFail("Expected KlipyError.invalidParameters, got \(error)")
                return
            }
            XCTAssertTrue(
                message.lowercased().contains("either ids or slugs"),
                "Unexpected invalidParameters message: \(message)"
            )
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testItemsThrowsWhenNeitherIdsNorSlugsProvided() async throws {
        // Given
        let client = makeDummyClient()
        
        do {
            _ = try await client.items(
                kind: .gif,
                ids: nil,
                slugs: nil
            )
            XCTFail("Expected items(kind:ids:slugs:) to throw for missing ids/slugs")
        } catch let error as KlipyError {
            guard case .invalidParameters(let message) = error else {
                XCTFail("Expected KlipyError.invalidParameters, got \(error)")
                return
            }
            XCTAssertTrue(
                message.lowercased().contains("either ids or slugs"),
                "Unexpected invalidParameters message: \(message)"
            )
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
