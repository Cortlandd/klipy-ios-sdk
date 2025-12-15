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

## Basic Sample App Screenshots
| Default State        | Search Screen          | Gif Results            | Sticker Results        | Clip Results           | Displaying selection   |
|----------------------|------------------------|------------------------|------------------------|------------------------|------------------------|
| ![](samples/img.png) | ![](samples/img_1.png) | ![](samples/img_2.png) | ![](samples/img_3.png) | ![](samples/img_4.png) | ![](samples/img_5.png) |

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

---

### KlipyCore (Sources/KlipyCore)

**Models & support**

* `KlipyConfiguration.swift`

  * Configuration struct for the client:

    * `apiKey: String` – your Klipy API key (embedded in the path).
    * `baseURL: URL` – defaults to `https://api.klipy.com`.
    * `defaultLocale: String?`, `defaultPerPage: Int?`.
  * You construct this once and pass it into `KlipyClient`.

* `KlipyMedia.swift`

  * Core model for responses:

    * `KlipyMediaType` enum: `.gif`, `.sticker`, `.clip`, `.meme`.
    * `KlipyMedia` struct:

      * `id`, `type`, `title`, `tags`, `blurPreview`, etc.
      * `file` for GIF-style responses, including buckets:

        * `hd`, `md`, `sm`, `xs: KlipyMediaFileBucket?`
      * Clip-style flat URLs: `mp4`, `gif`, `webp: URL?`.
    * Nested types: `KlipyMediaFileAsset`, `KlipyMediaFileBucket`, `KlipyMediaFile`, `KlipyMediaFileMeta`, etc.
    * Convenience helpers:

      * `previewURL: URL?` – best URL for a grid/thumbnail/preview.
      * `displayAspectRatio: CGFloat` – aspect ratio with some clamping so UI doesn’t explode.
  * This is what your app will mostly work with.

* `KlipyCategory.swift`

  * `KlipyCategory` – category model (e.g. “Happy”, “Excited”):

    * `category`, `query`, `previewURL`.
    * `id` derived from `query` for `Identifiable`.
  * Also includes a small `KlipySearchSuggestion`-style model (id/text) for autocomplete.

* `KlipyPage.swift`

  * Generic pagination wrapper:

    * `KlipyPage<Item>` containing:

      * `data: [Item]`
      * `currentPage`, `perPage`, `hasNext`
    * Matches Klipy’s paged API responses.

* `KlipyEnvelope.swift`

  * Generic top-level API envelope:

    * `result: Bool`
    * `data: T`
  * Used to decode everything from the API before unwrapping `data`.

* `KlipyError.swift`

  * Error enum for the whole SDK:

    * `.invalidURL`
    * `.httpError(statusCode: Int, body: Data?)`
    * `.decodingError(underlying: Error)`
    * `.transportError(underlying: Error)`
    * `.invalidParameters(message: String)`
  * `localizedDescription` is implemented so you can show human-readable messages easily.

* `KlipyCustomerIdProvider.swift`

  * Utility to resolve a persistent “customer id”:

    * If you pass an explicit `customerId` to the client, it uses that.
    * Else it:

      * Reads from `UserDefaults` (key: `"KlipySDK.customer_id"`).
      * If missing, generates from `UIDevice.current.identifierForVendor` or falls back to a random `UUID()`.
    * This `resolvedCustomerId` is then sent to the API as a query parameter to help with personalization/analytics.

* `KlipyItemsSelector.swift`

  * Simple enum:

    * `.ids([String])` or `.slugs([String])`
  * Used when you want to fetch specific items by id/slug.

---

**Client & endpoints**

* `KlipyClient.swift`

  * The main async/await HTTP client.
  * Public API:

    * Initializer:

      ```swift
      public init(
          configuration: KlipyConfiguration,
          urlSession: URLSession = .shared,
          customerId: String? = nil
      )
      ```

      Resolves `resolvedCustomerId` via `KlipyCustomerIdProvider`.
    * Generic request pipeline:

      * `buildURL(pathComponents: [String], queryItems: [String: String])`
      * `request<T: Decodable & Sendable>(...) async throws -> T`
    * Generic helpers used by the extensions:

      * `search(kind: KlipyMediaType, ...) async throws -> KlipyPage<KlipyMedia>`
      * `recent(kind: KlipyMediaType, ...) async throws -> KlipyPage<KlipyMedia>`
      * `item(kind: KlipyMediaType, slugOrId: String) async throws -> KlipyMedia`
      * `categories(kind: KlipyMediaType, ...) async throws -> [KlipyCategory]`
    * Autocomplete:

      * `searchAutocomplete(q: String, limit: Int = 10) async throws -> [String]`

        * Returns empty array instead of throwing on “empty JSON” quirks.
  * Implements error handling and decoding once, then reused by category/gif/sticker/etc. methods.

* `KlipyClient+GIF.swift`

  * Type-safe wrappers around the GIF endpoints:

    * `searchGIFs(query: String, page: Int? = nil, perPage: Int? = nil, locale: String? = nil)`
    * `recentGIFs(page: Int? = nil, perPage: Int? = nil, locale: String? = nil)`
    * `gif(slugOrId: String)`
    * `gifCategories(locale: String? = nil)`
  * All functions return `KlipyPage<KlipyMedia>` or `KlipyMedia` / `[KlipyCategory]`.

* `KlipyClient+Sticker.swift`

  * Same as GIF but for stickers:

    * `searchStickers`
    * `recentStickers`
    * `sticker`
    * `stickerCategories`

* `KlipyClient+Clip.swift`

  * Same for clips:

    * `searchClips`
    * `recentClips`
    * `clip`
    * `clipCategories`

* `KlipyClient+Meme.swift`

  * Same for memes:

    * `searchMemes`
    * `recentMemes`
    * `meme`
    * `memeCategories`

* `KlipyClient+Ads.swift`

  * Defines `KlipyAdParameters`:

    * `minWidth`, `maxWidth`, `minHeight`, `maxHeight`
    * `placement` (string, defaults from device/OS)
    * Device details (size, scale, model, OS version).
    * `asQueryParameters` converts it to `[String: String]`.
  * Helper:

    * `recentWithAds(kind: KlipyMediaType, page: Int? = nil, perPage: Int? = nil, locale: String? = nil, adParameters: KlipyAdParameters)`
  * Lets you get “ad-aware” recent feeds with extra context for the backend.

---

### KlipyUI (Sources/KlipyUI)

* `KlipyPickerMediaTab.swift`

  * Enum used for the picker’s tabs:

    * `.gifs`, `.stickers`, `.clips`, `.memes`.
  * Each tab exposes:

    * `title: String` – user-facing label (“GIFs”, “Stickers”, etc).
    * `mediaType: KlipyMediaType` – wired directly to the core API type.

* `KlipyPickerViewModel.swift`

  * `@MainActor` observable object used by the SwiftUI picker:

    * `@Published items: [KlipyMedia]`
    * `@Published isLoading: Bool`
    * `@Published lastError: KlipyError?`
    * `@Published query: String`
    * `@Published activeTab: KlipyPickerMediaTab`
    * Pagination state: `currentPage`, `hasNextPage`.
  * Handles:

    * Initial load (`initialTab` + trending for that type).
    * Running search when `query` changes.
    * Switching tabs.
    * Loading more when the grid scrolls near the bottom.
  * All network calls go through `KlipyClient`.

* `KlipyPickerView.swift`

  * The main SwiftUI picker you embed in your app.
  * Public initializer:

    ```swift
    public init(
        client: KlipyClient,
        initialTab: KlipyPickerMediaTab = .gifs,
        onSelect: @escaping (KlipyMedia) -> Void,
        onClose: (() -> Void)? = nil
    )
    ```
  * Internals:

    * Creates a `StateObject` for `KlipyPickerViewModel`.
    * Calls `KlipyUIBootstrap.configureIfNeeded()` to register WebP support with SDWebImage.
    * UI:

      * Handle bar at the top.
      * Search field for text input.
      * Segmented control-like tab bar for GIFs/Stickers/Clips/Memes.
      * Scrollable grid of media using `WebImage` from `SDWebImageSwiftUI`.
      * “Powered by Klipy” footer linking to Klipy’s site.
    * Callbacks:

      * `onSelect(media)` when user taps an item.
      * `onClose()` when user taps the close button.

* `KlipyMediaPreviewView.swift`

  * Internal preview view used inside the picker when you tap on an item.
  * Shows:

    * If it’s a clip: `AVPlayer` for mp4.
    * Otherwise: `WebImage` for previewURL.
  * Uses `media.displayAspectRatio` to size the preview.

* `KlipyUIBootstrap.swift`

  * Small bootstrap helper:

    * Registers `SDImageWebPCoder` with `SDImageCodersManager.shared`.
  * Called automatically by `KlipyPickerView`’s init so host apps don’t need to think about WebP.

* `.swift`

  * Empty stub (`KlipyThumbnailView` comment but no implementation). Safe to ignore or delete.

---

### Example app (Examples/KlipySampleTCA)

The example is built using **The Composable Architecture (TCA)** but it’s still a useful reference even if you’re not using TCA.

* `KlipyApp.swift`

  * `@main` entry point.
  * Creates a TCA store with `KlipyAppFeature` as the root reducer.
  * Root view: `KlipyAppView(store: ...)`.

* `KlipyAppFeature.swift`

  * App-level reducer:

    * State:

      * `selectedMedia: KlipyMedia?`
      * `destination` enum for navigation (nil vs picker sheet).
    * Actions:

      * `.openPickerTapped`
      * `.mediaSelected(KlipyMedia)`
      * `.closeTapped`
      * `.destination(...)`
    * Logic:

      * Presents picker on `.openPickerTapped`.
      * Stores selected media and dismisses picker when `.mediaSelected`.

* `KlipyAppView.swift`

  * Host SwiftUI view:

    * Displays selected media using `KlipyMediaPreview` (example-only view).
    * Button “Open Klipy Picker” that triggers `.openPickerTapped` on the store.
    * Presents `KlipyPickerSheet` via `.sheet` when destination is `picker`.
    * Creates a `KlipyClient` with an API key placeholder.

* `KlipyPickerFeature.swift`

  * Minimal reducer for picker sheet:

    * Just defines `mediaSelected` and `closeTapped` actions so parent can react.

* `KlipyPickerSheet.swift`

  * Wraps `KlipyPickerView` in a SwiftUI view that TCA can present:

    * Forwards `onSelect` and `onClose` to the TCA store actions.

* `KlipyMediaPreview.swift`

  * Example-only public SwiftUI view for showing a single `KlipyMedia`:

    * For clips, plays `mp4` with `AVPlayer`.
    * For non-clips, uses `WebImage` with `media.previewURL`.
  * Very similar to `KlipyMediaPreviewView` in the SDK, but public and meant as a reference.

---

## 2. Proposed README.md (Getting Started)

You can drop this (or a tweaked version) into `KlipySDK/README.md`.

````markdown
# Klipy iOS SDK

A lightweight Swift package for integrating **Klipy** GIFs, stickers, clips, and memes into your iOS app.

The SDK is split into two modules:

- **KlipyCore** – strongly-typed API client and models (no UI).
- **KlipyUI** – ready-made SwiftUI picker with search, tabs, and grid layout powered by KlipyCore.

> Minimum requirements: **iOS 15+**, Swift Concurrency (async/await), Swift Package Manager.

---

## Installation

### Swift Package Manager (Xcode)

1. In Xcode, open **File → Add Packages…**
2. Enter your Klipy SDK Git URL, for example:

   ```text
   https://github.com/your-org/KlipySDK.git
````

3. Choose the **KlipySDK** package.
4. Add the products you need to your target:

   * **`KlipyCore`** – for API-only integration.
   * **`KlipyUI`** – for the SwiftUI picker (this also pulls in `KlipyCore`).

### Swift Package Manager (Package.swift)

If you manage dependencies in `Package.swift`:

```swift
// In your Package.swift
.dependencies: [
    .package(url: "https://github.com/your-org/KlipySDK.git", from: "1.0.0")
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

---

## Quick Start – API-only (KlipyCore)

If you want to build a completely custom UI, you can use **KlipyCore** directly.

### Create a client

```swift
import KlipyCore

let client = KlipyClient(
    configuration: KlipyConfiguration(
        apiKey: "<YOUR_KLIPY_API_KEY>",
        defaultLocale: "en-US",
        defaultPerPage: 25
    )
    // Optional: override customerId if you have your own user identifier
    // customerId: "user-1234"
)
```

By default, the SDK will generate and persist a `customerId` based on the device’s identifierForVendor.

### Search GIFs

```swift
func loadGIFs() async {
    do {
        let page = try await client.searchGIFs(query: "hello")
        let items = page.data

        for media in items {
            print("id:", media.id, "preview:", media.previewURL ?? "none")
        }

        // page.hasNext tells you if you can request more pages.
    } catch {
        print("Klipy error:", error)
    }
}
```

### Get trending stickers

```swift
let page = try await client.recentStickers()
let stickers = page.data
```

### Work with clips

```swift
let clipsPage = try await client.searchClips(query: "funny")
let clips = clipsPage.data

if let clip = clips.first {
    // For clips, `media.file?.mp4` or flat `media.mp4` will be available
    print("Clip mp4:", clip.mp4)
}
```

### Categories

```swift
let gifCategories = try await client.gifCategories(locale: "en-US")
for category in gifCategories {
    print(category.category, "→", category.query)
}
```

### Autocomplete

```swift
let suggestions = try await client.searchAutocomplete(q: "hap")
print(suggestions) // ["happy", "happy birthday", ...]
```

---

## Working with `KlipyMedia`

`KlipyMedia` is designed to be flexible enough to represent GIFs, stickers, memes, and clips.

Common properties you’ll use:

```swift
let media: KlipyMedia = ...

media.id           // Normalized to String
media.type         // .gif, .sticker, .clip, .meme
media.title        // Optional title
media.tags         // [String]
media.blurPreview  // Optional hash / blur data (if you want fancy placeholders)

// For quick UI:
media.previewURL          // URL? – best guess for thumbnail/preview
media.displayAspectRatio  // CGFloat – safe aspect ratio for UI layout

// GIF-style buckets:
media.file?.sm?.webp?.url // etc.

// Clip-style flat URLs:
media.mp4                 // URL?
media.webp                // URL?
media.gif                 // URL?
```

You can use these to build more advanced UI if `KlipyPickerView` is too opinionated for your use case.

---

## Example app

An example app using **The Composable Architecture (TCA)** lives in:

```text
Examples/KlipySampleTCA/
```

Open:

```text
Examples/KlipySampleTCA/KlipySampleTCA.xcodeproj
```

The example shows:

* How to configure a `KlipyClient`.
* How to present `KlipyPickerView` in a sheet.
* How to handle the selected `KlipyMedia` and show a custom preview (`KlipyMediaPreview`).
* How to wire everything up in a unidirectional data flow architecture (TCA).

Even if you don’t use TCA, the SwiftUI views (`KlipyAppView`, `KlipyPickerSheet`, `KlipyMediaPreview`) are straightforward reference implementations for integrating Klipy into a chat-style interface.

---

## Error handling

All API methods throw `KlipyError`:

```swift
do {
    let page = try await client.searchGIFs(query: "hi")
} catch let error as KlipyError {
    print(error.localizedDescription)
} catch {
    print("Unexpected error:", error)
}
```

You’ll typically see:

* **Network issues** → `.transportError`.
* **HTTP 4xx/5xx** → `.httpError(statusCode:body:)`.
* **Decoding issues** → `.decodingError`.

## FAQ

> Q: Android version?

A: https://github.com/cortlandd/klipy-android-sdk

> Q: Do you work for Klipy?

A: Nope. I have a small personal project I'm working on that uses Gif images that I started 7 years ago but never finished. Started working on it again and searched for alternative to GIPHY. Found Klipy, they didn't have a full ios/android geared SDK. So I built one. 🤷‍♂️