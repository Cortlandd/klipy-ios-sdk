//
//  KlipyCustomerIdProvider.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/24/25.
//

import Foundation
import UIKit

public enum KlipyCustomerIdProvider {
    private static let storageKey = "KlipySDK.customer_id"

    public static func resolve(provided: String? = nil) -> String {
        // If the host app gave us their own ID, always prefer that.
        if let provided, !provided.isEmpty {
            return provided
        }

        // If we've already generated one, reuse it.
        if let existing = UserDefaults.standard.string(forKey: storageKey) {
            return existing
        }

        // Otherwise derive from IDFV if available, fall back to a random UUID.
        let base = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(base, forKey: storageKey)
        return base
    }
}
