import Foundation

enum KlipyChatUIKitConfig {
  static let apiKey: String = KlipyExampleAPIKey.current
  static let setupInstructions: String = KlipyExampleAPIKey.setupInstructions
}

private enum KlipyExampleAPIKey {
  static let setupInstructions = "Set KLIPY_API_KEY in the scheme environment or the app's KLIPY_API_KEY Info.plist value before running the live example."

  static var current: String {
    if let environmentValue = ProcessInfo.processInfo.environment["KLIPY_API_KEY"]?
      .trimmingCharacters(in: .whitespacesAndNewlines),
      !environmentValue.isEmpty
    {
      return environmentValue
    }

    if let infoValue = Bundle.main.object(forInfoDictionaryKey: "KLIPY_API_KEY") as? String {
      let trimmed = infoValue.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty {
        return trimmed
      }
    }

    return ""
  }
}
