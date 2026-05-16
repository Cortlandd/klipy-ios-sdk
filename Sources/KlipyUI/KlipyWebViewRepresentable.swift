//
//  KlipyWebViewRepresentable.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import SwiftUI

struct KlipyWebViewRepresentable: UIViewRepresentable {
    let url: URL?
    let htmlString: String?

    init(url: URL? = nil, htmlString: String? = nil) {
        self.url = url
        self.htmlString = htmlString
    }

    func makeUIView(context: Context) -> KlipyWebView {
        KlipyWebView()
    }

    func updateUIView(_ webView: KlipyWebView, context: Context) {
        if let url = url {
            webView.loadURL(url: url)
        } else if let htmlString = htmlString {
            webView.loadHTMLString(htmlString: htmlString)
        }
    }
}
