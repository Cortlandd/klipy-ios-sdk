# KlipyChatTCA (Example)

A tiny **chat-style sample** showing how to use the new **KlipyTray** (iOS keyboard tray via `inputAccessoryView`) with **SwiftUI + TCA**.

## Run it

1. Open: `KlipySDK/Examples/KlipyChatTCA/KlipyChatTCA.xcodeproj`
2. In `KlipyAppFeature.State(secretKey:)`, replace `"REPLACE_ME"` with your Klipy API key.
3. Build & run on iOS 15+.

## How it works

- The text input is a `UITextView` bridged into SwiftUI (`ChatTextView`).
- The tray is attached with `tv.inputAccessoryView = KlipyTrayAccessoryView(...)`.
- When the user selects a GIF / sticker / clip in the tray, the selection is routed into the reducer as `.mediaSelected(KlipyMedia)`.

## Notes

- This is intentionally minimal: messages are local-only, no networking beyond the tray fetching Klipy media.
- `KlipyMedia.previewURL` is used for the bubble preview.
