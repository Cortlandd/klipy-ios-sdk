# Klipy SDK for iOS

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
  - [Products](#products)
- [Configure Your API Key](#configure-your-api-key)
- [SDK Architecture](#sdk-architecture)
- [Common Integration Pattern](#common-integration-pattern)
  - [Using Klipy From a Chat Screen](#using-klipy-from-a-chat-screen)
- [Prebuilt Picker Surfaces](#prebuilt-picker-surfaces)
  - [SwiftUI Picker](#swiftui-picker)
  - [UIKit Picker Controller](#uikit-picker-controller)
  - [Picker Configuration](#picker-configuration)
  - [Theme](#theme)
  - [Confirmation Flow](#confirmation-flow)
- [Grid-Only Integration](#grid-only-integration)
  - [KlipyGridController](#klipygridcontroller)
  - [TCA-Backed Grid State](#tca-backed-grid-state)
- [Media Display](#media-display)
  - [KlipyMediaView](#klipymediaview)
  - [KlipyMediaPreviewView](#klipymediapreviewview)
- [Tray Integration](#tray-integration)
- [Advertisements](#advertisements)
  - [Mixed Media and Ad Feeds](#mixed-media-and-ad-feeds)
  - [Ad Request Behavior](#ad-request-behavior)
- [Offline and Error Handling](#offline-and-error-handling)
- [Examples](#examples)
- [Testing Notes](#testing-notes)

## Requirements

- iOS 16.0 or later
- Xcode 16 or later
- A Klipy API key
- Swift Package Manager or Xcode package integration

## Installation

### Swift Package Manager

Add the package URL in Xcode:

```text
https://github.com/Cortlandd/klipy-ios-sdk.git
```

Or add it in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Cortlandd/klipy-ios-sdk.git", from: "1.3.1")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "KlipySDK", package: "klipy-ios-sdk")
        ]
    )
]
```

### Products

- `KlipySDK`
  Default app-facing product. Includes `KlipyCore` and `KlipyUI`.
- `KlipyCore`
  Typed async client, models, paging, categories, item lookup, share/report flows, and content helpers.
- `KlipyUI`
  SwiftUI and UIKit picker/grid surfaces.
- `KlipyTray`
  Tray-style chat input surface built on top of TCA.

## Configure Your API Key

Import the SDK module you need:

```swift
import KlipyCore
```

Create a client:

```swift
let client = KlipyClient.live(apiKey: "<YOUR_KLIPY_API_KEY>")
```

Recommended key-handling pattern:

- Inject the key at the app boundary.
- Keep live keys out of git.
- For local development, prefer Xcode scheme environment variables such as `KLIPY_API_KEY`.
- Treat any embedded iOS key as an app credential, not a true secret.

The API base URL is fixed to Klipy's production API inside the SDK. App integrations provide the API key and optional defaults such as locale and page size, but they do not override the server root.

The SDK also sends:

- a browser-like mobile `User-Agent` for ad-capable feed requests
- `X-Klipy-Client: klipy-ios-sdk/<version> (iOS; community SDK)`

## SDK Architecture

The SDK is split into three layers:

- `KlipyCore`
  Networking, models, and API helpers.
- `KlipyUI`
  Picker, grid, preview, and UIKit bridge layers.
- `KlipyTray`
  Input-tray integration for chat-style experiences.

Stateful UI surfaces are reducer-driven where it matters:

- `KlipyPickerFeature`
- `KlipyGridFeature`
- `KlipyTrayFeature`

That keeps search, pagination, offline handling, and mixed media/ad feeds consistent across SwiftUI and UIKit entry points.

## Common Integration Pattern

In most apps, the best setup looks like this:

1. Resolve your API key in the app target, scene delegate, dependency container, or feature bootstrap layer.
2. Build a single `KlipyClient` or `KlipyConfiguration` for that app session.
3. Inject that client into the surface that needs Klipy:
   - a full picker
   - an embeddable grid
   - an input tray surface
   - a single media preview or message bubble
4. Let the SDK own the Klipy-specific loading, pagination, mixed media/ad rendering, and offline handling.

This keeps your app code focused on:

- presentation
- selection handling
- message sending
- analytics
- any higher-level feature state your product owns

### Using Klipy From a Chat Screen

Below is a more complete example of using Klipy inside a real chat screen. The app owns the message list and send flow, while the SDK owns the media-search experience.

```swift
import UIKit
import KlipyCore
import KlipyUI

final class ChatViewController: UIViewController, KlipyPickerViewControllerDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = MessageInputBar()

    private var messages: [ChatMessage] = []
    private let client: KlipyClient

    init(apiKey: String) {
        self.client = KlipyClient(
            configuration: .init(
                apiKey: apiKey,
                defaultLocale: "en-US",
                defaultPerPage: 24
            )
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        inputBar.onPlusTapped = { [weak self] in
            self?.presentKlipyPicker()
        }
        inputBar.onSendTapped = { [weak self] text in
            self?.sendTextMessage(text)
        }
    }

    private func presentKlipyPicker() {
        let controller = KlipyPickerViewController(
            client: client,
            config: .init(
                mediaTabs: [.gifs, .stickers, .clips, .memes, .emojis],
                maxItemsPerRow: 3,
                showTrending: true,
                showRecents: false,
                showConfirmationScreen: true,
                theme: .darkBlur
            )
        )
        controller.delegate = self
        controller.modalPresentationStyle = .pageSheet
        present(controller, animated: true)
    }

    func klipyPickerViewController(_ controller: KlipyPickerViewController, didSelect media: KlipyMedia) {
        messages.append(.media(media))
        tableView.reloadData()

        Task {
            do {
                _ = try await client.share(itemID: media.id)
            } catch {
                // Optional: ignore or log share/report failures.
            }
        }
    }

    func klipyPickerViewControllerDidClose(_ controller: KlipyPickerViewController) {}

    private func sendTextMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(.text(trimmed))
        tableView.reloadData()
    }
}
```

The important integration boundary here is:

- your app decides when to open Klipy
- your app decides what to do with the selected `KlipyMedia`
- the SDK handles fetching, rendering, ads, search, recents/trending, retry, and pagination

That same pattern also works well in:

- comment input flows
- DM or group chat screens
- story/reaction pickers
- sticker or meme attachments in editors

## Prebuilt Picker Surfaces

### SwiftUI Picker

```swift
import SwiftUI
import KlipyUI

struct ChatScreen: View {
    @State private var isShowingPicker = false
    @State private var selectedMedia: KlipyMedia?

    private let client = KlipyClient.live(apiKey: "<YOUR_KLIPY_API_KEY>")

    var body: some View {
        Button("Open Klipy Picker") {
            isShowingPicker = true
        }
        .sheet(isPresented: $isShowingPicker) {
            KlipyPickerView(
                client: client,
                config: .init(
                    mediaTabs: [.gifs, .stickers, .clips, .memes, .emojis],
                    maxItemsPerRow: 3,
                    showTrending: true,
                    showRecents: false,
                    initialTab: .gifs
                ),
                onSelect: { media in
                    selectedMedia = media
                    isShowingPicker = false
                },
                onClose: {
                    isShowingPicker = false
                }
            )
        }
    }
}
```

This is the fastest way to adopt the SDK if you want a self-contained picker that you present modally and then dismiss after selection.

### UIKit Picker Controller

```swift
import UIKit
import KlipyUI

final class ChatHostViewController: UIViewController, KlipyPickerViewControllerDelegate {
    private let client = KlipyClient.live(apiKey: "<YOUR_KLIPY_API_KEY>")

    func presentPicker() {
        let controller = KlipyPickerViewController(
            client: client,
            config: .init(
                mediaTabs: [.gifs, .stickers, .clips, .emojis],
                maxItemsPerRow: 3,
                showTrending: true,
                showConfirmationScreen: true,
                theme: .darkBlur
            )
        )
        controller.delegate = self
        present(controller, animated: true)
    }

    func klipyPickerViewController(_ controller: KlipyPickerViewController, didSelect media: KlipyMedia) {
        print(media.slug)
    }

    func klipyPickerViewControllerDidClose(_ controller: KlipyPickerViewController) {}
}
```

Use `dismissesAfterSelection` or `dismissesAfterClose` if your app wants to manage dismissal explicitly.
This controller is a good fit when your app is UIKit-first and you want a drop-in modal integration without building the search/feed shell yourself.

### Picker Configuration

`KlipyPickerConfig` controls:

- which tabs are shown
- feed density through `maxItemsPerRow`
- whether empty-query loads use trending, recents, or neither
- initial tab
- locale override
- confirmation flow
- theme

Example:

```swift
let config = KlipyPickerConfig(
    mediaTabs: [.gifs, .stickers, .clips],
    maxItemsPerRow: 3,
    locale: "en-US",
    showRecents: false,
    showTrending: true,
    initialTab: .gifs,
    showConfirmationScreen: true,
    theme: .darkBlur
)
```

Notes:

- `maxItemsPerRow` controls masonry density, not a strict fixed grid.
- If `initialTab` is not present in `mediaTabs`, the picker falls back to the first available tab.
- If both `showTrending` and `showRecents` are `false`, the picker waits for a query before loading results.
- `showTrending` and `showRecents` decide what the picker should do before the user types a search.
- `locale` lets your app pin the picker to a known content locale instead of inheriting device behavior.

### Theme

`KlipyTheme` supports:

- `.automatic`
- `.light`
- `.dark`
- `.lightBlur`
- `.darkBlur`

Use the same theme value across picker, grid, and tray when you want a consistent visual language.

### Confirmation Flow

Set `showConfirmationScreen` to `true` when you want selection to pass through a lightweight confirmation screen before returning media to your app.

## Grid-Only Integration

### KlipyGridController

Use `KlipyGridController` when your app already owns its own search field, tabs, or navigation shell and only needs Klipy’s feed rendering.

```swift
import UIKit
import KlipyUI

final class SearchResultsViewController: UIViewController, KlipyGridControllerDelegate {
    private let client = KlipyClient.live(apiKey: "<YOUR_KLIPY_API_KEY>")

    private lazy var gridController = KlipyGridController(
        client: client,
        content: .trending(kind: .gif, locale: "en-US"),
        configuration: .init(maxItemsPerRow: 3, theme: .automatic)
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        gridController.delegate = self
    }

    func search(for query: String) {
        gridController.setContent(.search(kind: .gif, query: query, locale: "en-US"))
    }

    func klipyGridController(_ controller: KlipyGridController, didSelect media: KlipyMedia) {
        print(media.slug)
    }
}
```

### TCA-Backed Grid State

If your app already uses TCA, you can work directly with `KlipyGridFeature` and `KlipyPickerFeature` instead of only using convenience wrappers.

The reducers handle:

- initial load
- debounced search
- pagination
- retry
- offline state
- mixed media/ad feed loading

That makes them useful when:

- your app already stores feature state in TCA
- you want to test tab switching or query transitions at the reducer layer
- you want SwiftUI and UIKit wrappers to share one source of truth

## Media Display

### KlipyMediaView

`KlipyMediaView` is the reusable UIKit media surface.

```swift
import UIKit
import KlipyUI

let mediaView = KlipyMediaView()
mediaView.cornerRadius = 12
mediaView.configure(with: media)
```

### KlipyMediaPreviewView

`KlipyMediaPreviewView` is the SwiftUI media preview surface for selected media, including clips.

Use these lower-level views when you already have your own picker, search shell, or message layout and only need a dependable Klipy rendering primitive.

```swift
import SwiftUI
import KlipyUI

KlipyMediaPreviewView(media: media)
```

## Tray Integration

`KlipyTrayView` is intended for chat and message-input flows where the Klipy surface behaves like an accessory tray rather than a full modal picker.

`KlipyTrayConfig` supports:

- media tabs
- `maxItemsPerRow`
- theme
- locale
- trending/recents behavior
- categories and search visibility

The tray is TCA-driven and shares the same mixed-content feed expectations as the picker and grid.
Use the tray when Klipy should feel attached to a message input area rather than presented as a full-screen or sheet-based picker.

## Advertisements

### Mixed Media and Ad Feeds

Klipy content feeds can return inline advertisements mixed with ordinary content.

That applies to:

- trending
- recent
- search

The SDK parses these as `KlipyContentItem` values and renders them inline in picker, grid, and tray feeds.
Your app should not assume that every feed item is media. If you build on top of the lower-level content models, always switch over the content type and handle advertisements explicitly.

### Ad Request Behavior

The SDK sends the ad-aware request shape required for inline ad inventory, including:

- `ad-iframe=1` on shared content requests
- browser-like mobile `User-Agent` behavior for content feeds
- the community SDK identification header

Ads are rendered automatically by the SDK feed surfaces. Integrators should treat them as first-class feed items rather than assuming every result is media.

## Offline and Error Handling

When the device is offline and a picker/grid/tray surface does not yet have loaded content, the SDK shows a retryable offline state instead of a generic transport error.

This behavior is handled consistently by the TCA-backed UI reducers.
If the UI already has loaded content and a later page fails, the SDK keeps the existing content visible and surfaces the failure through the reducer-backed state instead of blanking the feed.

## Examples

The repo includes example apps in `Examples/`:

- `KlipyChatUIKit`
- `KlipyChatTCA`
- `KlipySampleTCA`

The workspace to open is:

```text
KlipySDK.xcworkspace
```

Use the workspace when you want to run the sample apps from Xcode.

## Testing Notes

Useful verification commands:

```bash
xcodebuild build-for-testing -scheme KlipySDK-Package -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation -skipMacroValidation
xcodebuild build -workspace KlipySDK.xcworkspace -scheme KlipyChatUIKit -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation -skipMacroValidation
```

If you run into Xcode build database lock errors, rerun the builds sequentially instead of in parallel.
