# Installation guide

This guide is the recommended path for first-time users.

## Requirements

- macOS 13 or later
- Chrome, Edge, Arc, or another Chromium browser for webpage monitoring
- Accessibility permission for desktop app monitoring
- Optional: Swift 6 and Node.js if building from source

## 1. Install the macOS app

1. Download the latest release from GitHub Releases.
2. Move `AI Progress HUD.app` to `/Applications`.
3. Launch it once.
4. If macOS blocks the app, right-click the app in Finder and choose **Open**.

Community builds may be ad-hoc signed until notarized releases are available.

## 2. Pair the browser extension

1. Open `chrome://extensions`.
2. Enable **Developer mode**.
3. Click **Load unpacked**.
4. Select the repository or app-bundled `Extension` folder.
5. Open AI Progress HUD settings.
6. Copy the pairing token.
7. Paste it into the extension options page and click **Save and test**.
8. Reload any already-open AI tabs once.

The extension stores the token in browser-extension local storage. Webpages do not receive the token.

## 3. Enable desktop app detection

Open System Settings:

```text
Privacy & Security → Accessibility
```

Enable the exact running copy of `AI Progress HUD.app`. If you build locally often, stale Accessibility entries can accumulate; remove old copies and keep `/Applications/AI Progress HUD.app`.

Desktop monitoring uses Accessibility to inspect window titles and controls such as Stop, Retry, Verify, and Sign in. It does not persist the Accessibility tree.

## 4. Configure providers

Open HUD settings and use **Detection · 选择要扫描的 AI** to choose which providers appear:

- ChatGPT
- Claude
- Codex
- DeepSeek
- Yuanbao
- 灵感悬浮球

Turn off anything you do not want in the HUD.

## 5. Verify everything is connected

Open settings and check **Quick setup**:

- Local bridge: should be connected
- Browser extension: should be connected after pairing
- Desktop apps: should show Accessibility granted after permission is enabled
- Codex: should become live when local Codex activity is present

## Build from source

```bash
git clone https://github.com/IvyCHEN03/AI-Progress-HUD.git
cd AI-Progress-HUD
make test
make lint
make package
open "AI Progress HUD.app"
```

For stable Accessibility permission during local development, sign each build with the same certificate:

```bash
AIHUD_CODESIGN_IDENTITY="Apple Development: Your Name (TEAMID)" make package
```

