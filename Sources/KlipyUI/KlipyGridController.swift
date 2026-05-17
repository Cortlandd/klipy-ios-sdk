//
//  KlipyGridController.swift
//  KlipySDK
//
//  Created by Codex on 5/16/26.
//

import UIKit
import SwiftUI
import KlipyCore
import ComposableArchitecture

@MainActor
public protocol KlipyGridControllerDelegate: AnyObject {
    func klipyGridController(_ controller: KlipyGridController, didSelect media: KlipyMedia)
}

@MainActor
public final class KlipyGridController: UIViewController {
    public weak var delegate: (any KlipyGridControllerDelegate)?

    public let store: StoreOf<KlipyGridFeature>
    private let hostingController: UIHostingController<KlipyGridView>

    public init(
        client: KlipyClient,
        content: KlipyGridContent,
        configuration: KlipyGridConfiguration = .init()
    ) {
        self.store = Store(
            initialState: KlipyGridFeature.State(content: content, configuration: configuration)
        ) {
            KlipyGridFeature(
                client: client,
                fallbackLocale: client.configuration.defaultLocale ?? Locale.autoupdatingCurrent.identifier,
                perPage: client.configuration.defaultPerPage ?? 24
            )
        }
        self.hostingController = UIHostingController(
            rootView: KlipyGridView(store: store) { _ in }
        )

        super.init(nibName: nil, bundle: nil)

        hostingController.rootView = KlipyGridView(store: store) { [weak self] media in
            guard let self else { return }
            self.delegate?.klipyGridController(self, didSelect: media)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        embedHostingController()
    }

    public func setContent(_ content: KlipyGridContent) {
        store.send(.setContent(content))
    }

    private func embedHostingController() {
        addChild(hostingController)

        let hostedView = hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear

        view.addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: view.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        hostingController.didMove(toParent: self)
    }
}
