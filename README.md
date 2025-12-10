# UNDER CONSTRUCTION

![](Logos/logo.png)

# Klipy iOS SDK

A lightweight Swift package for integrating **Klipy** GIFs, stickers, clips, and memes into your iOS app.

The SDK is split into two modules:
- **KlipyCore** – Strongly-typed API client and models (no UI).
- **KlipyUI** – Ready-made SwiftUI picker with search, tabs, and grid layout powered by KlipyCore.

> Minimum requirements: **iOS 15+**, Swift Concurrency (async/await), Swift Package Manager.



## Installation

### Swift Package Manager (Xcode)

1. In Xcode, open **File → Add Packages…**
2. Enter your Klipy SDK Git URL, for example:

   ```text
   https://github.com/Cortlandd/klipy-ios-sdk.git
3. Choose the klipy-ios-sdk package.

4. Add the products you need to your target:
- KlipyCore – for API-only integration.
- KlipyUI – for the SwiftUI picker (this also pulls in KlipyCore).

**Swift Package Manager (Package.swift)**
If you manage dependencies in Package.swift:
```
// In your Package.swift
.dependencies: [
    .package(url: "https://github.com/Cortlandd/klipy-ios-sdk.git", from: "1.0.0")
],
.targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "KlipyCore", package: "KlipySDK"),
            .product(name: "KlipyUI", package: "KlipySDK")
        ]
    )
]
```

## Quick Start – Full-screen Klipy picker (SwiftUI)
This is the simplest way to get Klipy into your app: present the built-in picker and handle the selected media.

```swift
import SwiftUI
import KlipyCore
import KlipyUI

struct ChatView: View {
    @State private var isShowingPicker = false
    @State private var selectedMedia: KlipyMedia?

    // Create a client once and reuse it
    private let client = KlipyClient(
        configuration: KlipyConfiguration(
            apiKey: "<YOUR_KLIPY_API_KEY>"
        )
    )

    var body: some View {
        VStack(spacing: 16) {
            if let media = selectedMedia {
                // Use your own preview UI or mirror the example’s KlipyMediaPreview
                AsyncPreview(media: media)
            } else {
                Text("No media selected yet")
                    .foregroundColor(.secondary)
            }

            Button("Open Klipy Picker") {
                isShowingPicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $isShowingPicker) {
            KlipyPickerView(
                client: client,
                initialTab: .gifs, // .stickers, .clips, .memes
                onSelect: { media in
                    // Handle selection (send in a message, etc.)
                    selectedMedia = media
                    isShowingPicker = false
                },
                onClose: {
                    // User tapped the close button
                    isShowingPicker = false
                }
            )
        }
    }
}

/// Very simple example preview using the convenient `previewURL` helper.
/// In a real app you might want something closer to the example project's `KlipyMediaPreview`.
struct AsyncPreview: View {
    let media: KlipyMedia

    var body: some View {
        if let url = media.previewURL {
            // SDWebImageSwiftUI is a transitive dependency of KlipyUI
            SDWebImageSwiftUI.WebImage(url: url)
                .resizable()
                .indicator(.activity)
                .aspectRatio(media.displayAspectRatio, contentMode: .fit)
                .cornerRadius(8)
                .padding(.horizontal, 16)
        } else {
            Image(systemName: "photo")
                .foregroundColor(.secondary)
        }
    }
}
```

Notes:

- `KlipyPickerView`:
  - Uses KlipyPickerViewModel internally.
  - Automatically registers WebP support via KlipyUIBootstrap.
  - Handles search input, pagination, tab switching, and grid layout.
- `KlipyMedia`:
  - Provides previewURL and displayAspectRatio helpers for quick UI integration.