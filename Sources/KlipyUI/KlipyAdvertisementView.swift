//
//  KlipyAdvertisementView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import SwiftUI
import WebKit
import KlipyCore

public struct KlipyAdvertisementView: View {
    private let advertisement: KlipyAdvertisement

    public init(advertisement: KlipyAdvertisement) {
        self.advertisement = advertisement
    }

    public var body: some View {
        KlipyAdvertisementWebView(advertisement: advertisement)
            .frame(height: CGFloat(advertisement.height ?? 100))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
            )
            .accessibilityLabel("Sponsored content")
    }
}

private struct KlipyAdvertisementWebView: UIViewRepresentable {
    let advertisement: KlipyAdvertisement

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.load(advertisement)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(advertisement)
    }
}

private extension WKWebView {
    func load(_ advertisement: KlipyAdvertisement) {
        if let url = advertisement.contentURL,
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            load(URLRequest(url: url))
        } else {
            loadHTMLString(advertisement.content, baseURL: nil)
        }
    }
}
