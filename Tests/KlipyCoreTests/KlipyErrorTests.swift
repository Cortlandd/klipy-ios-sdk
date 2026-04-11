//
//  KlipyErrorTests.swift
//  KlipySDK
//
//  Created by Cortland Walker on 4/11/26.
//

import XCTest
@testable import KlipyCore

final class KlipyErrorTests: XCTestCase {

    func testTransportErrorsDetectOfflineConnectivityFailures() {
        let error = KlipyError.transportError(underlying: URLError(.notConnectedToInternet))

        XCTAssertTrue(error.isConnectivityError)
        XCTAssertEqual(
            error.description,
            "No internet connection. Connect to the internet and try again."
        )
    }

    func testTransportErrorsDoNotTreatGenericFailuresAsOffline() {
        let error = KlipyError.transportError(underlying: URLError(.badServerResponse))

        XCTAssertFalse(error.isConnectivityError)
        XCTAssertEqual(
            error.description,
            "Network/transport error: \(URLError(.badServerResponse).localizedDescription)"
        )
    }
}
