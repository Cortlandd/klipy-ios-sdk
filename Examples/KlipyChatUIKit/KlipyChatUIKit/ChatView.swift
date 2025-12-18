import UIKit
import SwiftUI
import KlipyCore
import KlipyTray
import KlipyUI

final class ChatViewController: UIViewController {

  private let tableView = UITableView(frame: .zero, style: .plain)
  private let composer = ComposerView()

  private var messages: [ChatMessage] = ChatSeed.sampleConversation()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Klipy Chat (UIKit)"
    view.backgroundColor = .systemGroupedBackground

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.separatorStyle = .none
    tableView.keyboardDismissMode = .interactive
    tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.reuseID)
    tableView.dataSource = self

    composer.translatesAutoresizingMaskIntoConstraints = false
    composer.delegate = self

    view.addSubview(tableView)
    view.addSubview(composer)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: composer.topAnchor),

      composer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      composer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      composer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    reloadAndScrollToBottom(animated: false)
  }

  private func reloadAndScrollToBottom(animated: Bool) {
    tableView.reloadData()
    guard !messages.isEmpty else { return }
    let indexPath = IndexPath(row: messages.count - 1, section: 0)
    tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
  }

  private func presentTray() {
    let apiKey = KlipyChatUIKitConfig.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !apiKey.isEmpty else {
      let alert = UIAlertController(
        title: "Missing API Key",
        message: "Set KlipyChatUIKitConfig.apiKey before testing the tray.",
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
      return
    }

    let client = KlipyClient(configuration: .init(apiKey: apiKey))

    let tray = KlipyTrayView(
      client: client,
      config: .init(
        mediaTabs: [.gifs, .stickers, .clips, .memes],
        initialTab: .gifs,
        columns: 3,
        showTrending: true,
        showRecents: false,
        showCategories: true,
        showSearch: true
      ),
      onSelect: { [weak self] media in
        guard let self else { return }
        self.dismiss(animated: true)
        self.messages.append(.init(id: UUID(), isMe: true, date: Date(), kind: .media(media)))
        self.reloadAndScrollToBottom(animated: true)
      },
      onError: { _ in }
    )

    let host = UIHostingController(rootView: tray)
    host.modalPresentationStyle = .pageSheet

    if let sheet = host.sheetPresentationController {
      sheet.detents = [.medium(), .large()]
      sheet.prefersGrabberVisible = true
      sheet.preferredCornerRadius = 0
      sheet.prefersScrollingExpandsWhenScrolledToEdge = true
    }

    present(host, animated: true)
  }
}

extension ChatViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    messages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.reuseID, for: indexPath) as! MessageCell
    cell.configure(message: messages[indexPath.row])
    return cell
  }
}

extension ChatViewController: ComposerViewDelegate {
  func composerDidTapPlus() {
    presentTray()
  }

  func composerDidSendText(_ text: String) {
    messages.append(.init(id: UUID(), isMe: true, date: Date(), kind: .text(text)))
    reloadAndScrollToBottom(animated: true)
  }
}
