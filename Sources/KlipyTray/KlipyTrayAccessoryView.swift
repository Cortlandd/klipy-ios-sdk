//
//  KlipyTrayAccessoryView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 12/17/25.
//

import UIKit
import SwiftUI
import KlipyCore
import ComposableArchitecture

/// A UIKit `inputAccessoryView` wrapper hosting `KlipyTrayView`.
///
/// This is the iOS equivalent of an Android "tray" panel above the keyboard.
public final class KlipyTrayAccessoryView: UIView {

    private let hostingController: UIHostingController<KlipyTrayView>
    private let height: CGFloat

    public init(
        client: KlipyClient,
        config: KlipyTrayConfig = .init(),
        height: CGFloat = 320,
        onSelect: @escaping (KlipyMedia) -> Void,
        onError: @escaping (String) -> Void = { _ in }
    ) {
        self.height = height

        let store = Store(initialState: KlipyTrayFeature.State()) {
            KlipyTrayFeature(client: client)
        }

        self.hostingController = UIHostingController(
            rootView: KlipyTrayView(store: store, onSelect: onSelect, onError: onError)
        )

        super.init(frame: .zero)

        backgroundColor = .clear

        let hosted = hostingController.view!
        hosted.backgroundColor = .clear
        hosted.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hosted)

        NSLayoutConstraint.activate([
            hosted.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosted.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosted.topAnchor.constraint(equalTo: topAnchor),
            hosted.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: height)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
}
