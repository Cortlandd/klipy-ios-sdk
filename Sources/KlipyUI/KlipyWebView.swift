//
//  KlipyWebView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import UIKit
@preconcurrency import WebKit

private let adIframeQueryName = "ad-iframe"
private let adIframeQueryValue = "1"

public final class KlipyWebView: UIView {
    private var webView: WKWebView!

    public init() {
        super.init(frame: .zero)

        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.frame = frame

        webView.navigationDelegate = self
        webView.isOpaque = true

        addSubview(webView)
        layoutWebView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func loadURL(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    public func loadHTMLString(htmlString: String) {
        if let url = normalizedAdURL(from: htmlString) {
            loadURL(url: url)
            return
        }

        webView.loadHTMLString(htmlString, baseURL: nil)
    }

    private func layoutWebView() {
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

extension KlipyWebView: WKNavigationDelegate {
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if navigationAction.navigationType == .linkActivated {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

extension KlipyWebView {
    func normalizedAdURL(from value: String) -> URL? {
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        var queryItems = components.queryItems ?? []
        if queryItems.contains(where: { $0.name == adIframeQueryName }) == false {
            queryItems.append(URLQueryItem(name: adIframeQueryName, value: adIframeQueryValue))
            components.queryItems = queryItems
        }

        return components.url
    }
}
