//
//  KlipyAdvertisementView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/15/26.
//

import SwiftUI
import KlipyCore

public struct KlipyAdvertisementView: View {
    private let advertisement: KlipyAdvertisement

    public init(advertisement: KlipyAdvertisement) {
        self.advertisement = advertisement
    }

    public var body: some View {
        KlipyWebViewRepresentable(htmlString: advertisement.content)
            .frame(height: CGFloat(advertisement.height ?? 100))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
            )
            .accessibilityLabel("Sponsored content")
    }
}
