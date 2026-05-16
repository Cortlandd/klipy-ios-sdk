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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .accessibilityLabel("Sponsored content")
    }
}
