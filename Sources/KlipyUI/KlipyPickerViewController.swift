//
//  KlipyPickerViewController.swift
//  KlipySDK
//
//  Created by Codex on 5/16/26.
//

import UIKit
import SwiftUI
import KlipyCore

@MainActor
public protocol KlipyPickerViewControllerDelegate: AnyObject {
    func klipyPickerViewController(_ controller: KlipyPickerViewController, didSelect media: KlipyMedia)
    func klipyPickerViewControllerDidClose(_ controller: KlipyPickerViewController)
}

@MainActor
public final class KlipyPickerViewController: UIViewController {
    public weak var delegate: (any KlipyPickerViewControllerDelegate)?

    /// When `true`, the controller dismisses itself after media selection.
    public var dismissesAfterSelection: Bool

    /// When `true`, the controller dismisses itself after the close affordance is used.
    public var dismissesAfterClose: Bool

    private let hostingController: UIHostingController<KlipyPickerView>

    public init(
        client: KlipyClient,
        config: KlipyPickerConfig = .init(),
        dismissesAfterSelection: Bool = true,
        dismissesAfterClose: Bool = true
    ) {
        self.dismissesAfterSelection = dismissesAfterSelection
        self.dismissesAfterClose = dismissesAfterClose

        self.hostingController = UIHostingController(
            rootView: KlipyPickerView(
                client: client,
                config: config,
                onSelect: { _ in },
                onClose: nil
            )
        )

        super.init(nibName: nil, bundle: nil)

        hostingController.rootView = KlipyPickerView(
            client: client,
            config: config,
            onSelect: { [weak self] media in
                self?.handleSelection(media)
            },
            onClose: { [weak self] in
                self?.handleClose()
            }
        )
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

    func handleSelection(_ media: KlipyMedia) {
        let notify = { [weak self] in
            guard let self else { return }
            self.delegate?.klipyPickerViewController(self, didSelect: media)
        }

        if dismissesAfterSelection, presentingViewController != nil {
            dismiss(animated: true, completion: notify)
        } else {
            notify()
        }
    }

    func handleClose() {
        let notify = { [weak self] in
            guard let self else { return }
            self.delegate?.klipyPickerViewControllerDidClose(self)
        }

        if dismissesAfterClose, presentingViewController != nil {
            dismiss(animated: true, completion: notify)
        } else {
            notify()
        }
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
