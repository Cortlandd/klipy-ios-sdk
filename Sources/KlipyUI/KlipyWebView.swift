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
private let fullBleedViewportHTML = """
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
"""
private let fullBleedStyleHTML = """
<style>
html, body {
    margin: 0 !important;
    padding: 0 !important;
    width: 100% !important;
    height: 100% !important;
    overflow: hidden !important;
    background: transparent !important;
}
body {
    position: relative !important;
}
iframe, img, video, canvas, object, embed, svg {
    display: block !important;
    width: 100% !important;
    height: 100% !important;
    max-width: 100% !important;
    max-height: 100% !important;
    margin: 0 !important;
    padding: 0 !important;
    border: 0 !important;
    overflow: hidden !important;
}
</style>
"""
private let fullBleedJavaScriptSource = """
(function() {
    function applyFullBleedLayout() {
        var root = document.documentElement;
        var body = document.body;
        [root, body].forEach(function(element) {
            if (!element) { return; }
            element.style.margin = '0';
            element.style.padding = '0';
            element.style.width = '100%';
            element.style.height = '100%';
            element.style.overflow = 'hidden';
            element.style.background = 'transparent';
        });

        var media = document.querySelectorAll('iframe, img, video, canvas, object, embed, svg');
        media.forEach(function(element) {
            element.setAttribute('scrolling', 'no');
            element.style.display = 'block';
            element.style.width = '100%';
            element.style.height = '100%';
            element.style.maxWidth = '100%';
            element.style.maxHeight = '100%';
            element.style.margin = '0';
            element.style.padding = '0';
            element.style.border = '0';
            element.style.overflow = 'hidden';
        });
    }

    applyFullBleedLayout();
    window.addEventListener('load', applyFullBleedLayout);
})();
"""

public final class KlipyWebView: UIView {
    private var webView: WKWebView!

    public init() {
        super.init(frame: .zero)

        let webConfiguration = Self.makeWebConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.frame = frame

        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.contentInset = .zero
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        clipsToBounds = true

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

        webView.loadHTMLString(normalizedHTMLDocument(from: htmlString), baseURL: nil)
    }

    private func layoutWebView() {
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private static func makeWebConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        controller.addUserScript(
            WKUserScript(
                source: fullBleedJavaScriptSource,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )
        configuration.userContentController = controller
        return configuration
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

    func normalizedHTMLDocument(from value: String) -> String {
        if value.localizedCaseInsensitiveContains("<html") {
            return value
        }

        return """
        <!doctype html>
        <html>
        <head>
        \(fullBleedViewportHTML)
        \(fullBleedStyleHTML)
        </head>
        <body>
        \(value)
        </body>
        </html>
        """
    }
}
