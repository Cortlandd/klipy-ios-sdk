//
//  KlipyAdRequestContext.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import Foundation
import UIKit
import WebKit

actor KlipyBrowserUserAgentProvider {
    static let shared = KlipyBrowserUserAgentProvider()

    private var cachedUserAgent: String?

    func userAgent() async -> String {
        if let cachedUserAgent {
            return cachedUserAgent
        }

        let resolvedUserAgent: String
        if let browserUserAgent = await Self.fetchFromWebView() {
            resolvedUserAgent = browserUserAgent
        } else {
            resolvedUserAgent = await Self.fallbackUserAgent()
        }
        cachedUserAgent = resolvedUserAgent
        return resolvedUserAgent
    }

    @MainActor
    private static func fetchFromWebView() async -> String? {
        let webView = WKWebView(frame: .zero)
        return await withCheckedContinuation { continuation in
            webView.evaluateJavaScript("navigator.userAgent") { result, _ in
                continuation.resume(returning: result as? String)
            }
        }
    }

    @MainActor
    private static func fallbackUserAgent() -> String {
        let systemVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(systemVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
    }
}

enum KlipyAdRequestContext {
    static func defaultQueryItems(userAgent: String) async -> [String: String] {
        await MainActor.run {
            let deviceWidth = max(50, Int(UIScreen.main.bounds.width.rounded(.down)))
            var params: [String: String] = [
                "ad-iframe": "1",
                "ad-min-width": "50",
                "ad-max-width": String(deviceWidth),
                "ad-min-height": "50",
                "ad-max-height": "250",
                "ad-os": "ios",
                "ad-osv": UIDevice.current.systemVersion,
                "ad-make": "apple",
                "ad-user-agent": userAgent
            ]

            if let languageCode = Locale.autoupdatingCurrent.language.languageCode?.identifier {
                params["ad-language"] = languageCode
            } else if let languageCode = Locale.autoupdatingCurrent.languageCode {
                params["ad-language"] = languageCode
            }

            let modelName = deviceHardwareVersion()
            if !modelName.isEmpty {
                params["ad-hwv"] = modelName
            }

            if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
               !appVersion.isEmpty {
                params["ad-app-version"] = appVersion
            }

            return params
        }
    }

    @MainActor
    private static func deviceHardwareVersion() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                String(cString: $0)
            }
        }
        return machine
    }
}
