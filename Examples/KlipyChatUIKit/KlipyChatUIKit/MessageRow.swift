import UIKit
import KlipyCore
import SDWebImage

protocol ComposerViewDelegate: AnyObject {
  func composerDidTapPlus()
  func composerDidSendText(_ text: String)
}

final class ComposerView: UIView, UITextViewDelegate {

  weak var delegate: ComposerViewDelegate?

  private let plusButton = UIButton(type: .system)
  private let sendButton = UIButton(type: .system)
  private let textView = UITextView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .systemBackground

    plusButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
    plusButton.tintColor = .systemBlue
    plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)

    sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
    sendButton.tintColor = .systemBlue
    sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

    textView.font = .systemFont(ofSize: 16)
    textView.backgroundColor = .secondarySystemBackground
    textView.layer.cornerRadius = 18
    textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    textView.returnKeyType = .send
    textView.delegate = self

    let stack = UIStackView(arrangedSubviews: [plusButton, textView, sendButton])
    stack.axis = .horizontal
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)

    NSLayoutConstraint.activate([
      plusButton.widthAnchor.constraint(equalToConstant: 30),
      plusButton.heightAnchor.constraint(equalToConstant: 30),

      sendButton.widthAnchor.constraint(equalToConstant: 32),
      sendButton.heightAnchor.constraint(equalToConstant: 32),

      stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      stack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

      textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
    ])
  }

  required init?(coder: NSCoder) { fatalError() }

  @objc private func plusTapped() {
    delegate?.composerDidTapPlus()
  }

  @objc private func sendTapped() {
    let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    textView.text = ""
    delegate?.composerDidSendText(text)
  }

  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if text == "\n" {
      sendTapped()
      return false
    }
    return true
  }
}

final class MessageCell: UITableViewCell {
  static let reuseID = "MessageCell"

  private let bubble = UIView()
  private let label = UILabel()
  private let mediaView = SDAnimatedImageView()   // ✅ animated

  private var leading: NSLayoutConstraint!
  private var trailing: NSLayoutConstraint!

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    bubble.layer.cornerRadius = 18
    bubble.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(bubble)

    label.numberOfLines = 0
    label.font = .systemFont(ofSize: 16)
    label.translatesAutoresizingMaskIntoConstraints = false
    bubble.addSubview(label)

    // SDAnimatedImageView setup
    mediaView.clipsToBounds = true
    mediaView.contentMode = .scaleAspectFill
    mediaView.layer.cornerRadius = 16
    mediaView.translatesAutoresizingMaskIntoConstraints = false
    mediaView.autoPlayAnimatedImage = true
    mediaView.clearBufferWhenStopped = true
    mediaView.backgroundColor = .secondarySystemBackground
    bubble.addSubview(mediaView)

    leading = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
    trailing = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)

    NSLayoutConstraint.activate([
      bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
      bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
      bubble.widthAnchor.constraint(lessThanOrEqualToConstant: 280),

      leading,

      label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
      label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
      label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
      label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),

      mediaView.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
      mediaView.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 10),
      mediaView.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -10),
      mediaView.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),
      mediaView.heightAnchor.constraint(equalToConstant: 180),
    ])

    mediaView.isHidden = true
  }

  required init?(coder: NSCoder) { fatalError() }

  override func prepareForReuse() {
    super.prepareForReuse()
    label.text = nil
    mediaView.sd_cancelCurrentImageLoad()
    mediaView.image = nil
    mediaView.stopAnimating()
    mediaView.isHidden = true
    label.isHidden = false
  }

  func configure(message: ChatMessage) {
    // alignment
    if message.isMe {
      leading.isActive = false
      trailing.isActive = true
    } else {
      trailing.isActive = false
      leading.isActive = true
    }

    switch message.kind {
    case let .text(text):
      mediaView.isHidden = true
      label.isHidden = false
      label.text = text
      bubble.backgroundColor = message.isMe ? UIColor.systemBlue : UIColor.secondarySystemBackground
      label.textColor = message.isMe ? .white : .label

    case let .media(media):
      label.isHidden = true
      mediaView.isHidden = false
      bubble.backgroundColor = message.isMe
        ? UIColor.systemBlue.withAlphaComponent(0.12)
        : UIColor.secondarySystemBackground

      let url = media.gifURL ?? media.previewURL
      if let url {
        mediaView.sd_setImage(with: url)
      } else {
        mediaView.image = nil
      }
    }
  }
}
