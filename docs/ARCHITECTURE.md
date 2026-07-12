# Architecture

AI Progress HUD normalizes several local observation sources into one `AIJobSnapshot` model.

## Components

### Native macOS app

- SwiftUI renders the floating HUD and settings.
- `JobStore` owns normalized task state and ordering.
- `LocalHTTPServer` accepts authenticated browser events on loopback only.
- `DesktopAIMonitor` inspects supported app windows through Accessibility.
- `CodexMonitor` reads thread identity and activity timestamps from local Codex SQLite databases.
- `AppController` owns menu bar, windows, monitors, and single-instance lifecycle.

### Chromium extension

- `content.js` contains isolated provider selectors and state heuristics.
- `background.js` attaches browser tab/window identity, sends events to localhost, and executes tab activation commands.
- `options.js` validates the pairing token against the native app.

## Normalized state

```swift
enum AIJobState {
    case idle, thinking, streaming, completed
    case attention, error, disconnected
}
```

Every task also carries provider, stable local identity, display title, timestamps, source, and optional browser routing IDs.

## Trust boundaries

```text
Supported webpage ──content state──► extension service worker
                                         │ token
                                         ▼
                                  127.0.0.1:17321
                                         │
Desktop controls ──Accessibility──────► JobStore ◄──Codex metadata databases
                                         │
                                         ▼
                                    SwiftUI HUD
```

The browser page never learns the pairing token. The extension owns it in extension-local storage. The native bridge rejects commands without that token and rejects non-loopback connections.

## Adapter contract

Provider adapters should emit state transitions without transmitting message text. Selectors should prefer stable test IDs, ARIA labels, and generation controls over CSS class names.

Website changes are expected. When an adapter becomes uncertain, it should report `disconnected` or a diagnosable adapter state rather than guess.
