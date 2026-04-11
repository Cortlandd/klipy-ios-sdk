# Klipy iOS SDK

![](Logos/logo.png)

An unofficial Swift Package for integrating Klipy GIFs, stickers, clips, and memes into iOS apps.

This repository is not affiliated with, endorsed by, or owned by Klipy.

## Status

The production-ready surfaces in this repo today are:
- `KlipyCore`, which provides the typed async client, models, pagination, categories, item lookup, recent/share/report flows, and stable `customer_id` handling.
- `KlipyUI`, which provides a callback-based SwiftUI picker with tabs, search, previews, and infinite scrolling.

`KlipyTray` is also included as an optional tray-style surface for chat and composer flows, built on top of The Composable Architecture for teams already using that stack.
The main remaining release check is to run the live integration flows with your own Klipy API key and confirm the exact endpoint and content behavior you want in your environment.

## Products

- `KlipySDK`
  The primary install product for most apps. Includes `KlipyCore` and `KlipyUI`.
- `KlipyCore`
  The programmatic client and model layer.
- `KlipyUI`
  The SwiftUI picker layer. Re-exports `KlipyCore`.
- `KlipyTray`
  A tray-style picker experience for keyboard and composer surfaces.

## Requirements

- iOS 16+
- Swift Concurrency (`async` / `await`)
- Swift Package Manager or Xcode package integration

## Installation

### Xcode

1. Open **File -> Add Packages...**
2. Enter your repository URL, for example:

```text
https://github.com/Cortlandd/klipy-ios-sdk.git
```

3. Add `KlipySDK` for the default app-facing install path.
4. Add `KlipyCore` or `KlipyTray` separately only when you want those products explicitly.

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/Cortlandd/klipy-ios-sdk.git", from: "1.0.0")
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

Most apps can simply:

```swift
import KlipyUI
```

## Quick Start

### Programmatic client

```swift
import KlipyCore

let client = KlipyClient.live(apiKey: "<YOUR_KLIPY_API_KEY>")
let page = try await client.searchGIFs(
    query: "excited",
    page: 1,
    perPage: 24,
    locale: "en-US"
)

print(page.data.first?.slug ?? "No results")
```

### SwiftUI picker

```swift
import SwiftUI
import KlipyUI

struct ChatView: View {
    @State private var isShowingPicker = false
    @State private var selectedMedia: KlipyMedia?

    private let client = KlipyClient.live(apiKey: "<YOUR_KLIPY_API_KEY>")

    var body: some View {
        VStack(spacing: 16) {
            if let selectedMedia {
                KlipyMediaPreviewView(media: selectedMedia)
            }

            Button("Open Klipy Picker") {
                isShowingPicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $isShowingPicker) {
            KlipyPickerView(
                client: client,
                initialTab: .gifs,
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

### Tray integration

```swift
import SwiftUI
import KlipyTray

struct ComposerTrayHost: View {
    private let client = KlipyClient.live(apiKey: "<YOUR_KLIPY_API_KEY>")

    var body: some View {
        KlipyTrayView(client: client) { media in
            print("Selected media: \(media.slug)")
        }
    }
}
```

## Screenshots

| Default State        | Search Screen          | GIF Results            | Sticker Results        | Clip Results           | Displaying Selection   |
|----------------------|------------------------|------------------------|------------------------|------------------------|------------------------|
| ![](Samples/img.png) | ![](Samples/img_1.png) | ![](Samples/img_2.png) | ![](Samples/img_3.png) | ![](Samples/img_4.png) | ![](Samples/img_5.png) |

## Verification

The package currently includes:
- request and parameter validation tests for `KlipyCore`
- POST route coverage for share and recent-removal flows
- picker view-model tests for tab changes and debounced search behavior

## Key Modules

- `Sources/KlipyCore`
  Core networking, models, pagination, categories, and typed endpoint helpers.
- `Sources/KlipyUI`
  SwiftUI picker, media preview helpers, and UI bootstrap code.
- `Sources/KlipyTray`
  Tray-specific configuration and TCA-powered tray surface.

## License

This repository is distributed under Apache License 2.0.
