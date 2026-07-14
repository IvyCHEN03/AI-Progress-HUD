# Troubleshooting

## The HUD is empty

Open settings and inspect **Quick setup**:

- **Local bridge unavailable** — quit duplicate copies of the app and relaunch the copy you intend to use.
- **Browser extension is not connected** — save the pairing token and reload the extension. A connected status no longer requires an AI tab to be open; supported tabs begin reporting automatically when opened or refreshed.
- **Desktop permission missing** — enable the exact running app copy under System Settings → Privacy & Security → Accessibility.

## The extension says connected but no task appears

Confirm the options page shows version `v0.2` or later. In `chrome://extensions`, click Reload, then refresh the AI tab. The extension only runs on supported hostnames.

## Accessibility is enabled but desktop apps still say permission required

macOS permissions are tied to a specific app signature and path. Open AI Progress HUD settings, copy the **Current app** path, and make sure that exact app is enabled in System Settings → Privacy & Security → Accessibility. Remove stale duplicate entries. For repeated local builds, set `AIHUD_CODESIGN_IDENTITY` to a stable Developer ID or local signing certificate before running `make package`; otherwise ad-hoc signing can make macOS treat each rebuilt app as a new accessibility client.

## A website changed and status is wrong

Open an **Adapter broken** issue. Include provider, browser version, locale, expected state, observed state, and a screenshot with conversation content redacted. Never post cookies or account tokens.

## Codex shows multiple rows

That is intentional only while multiple Codex conversations are actively running. Rows are labeled by conversation title, and identical titles are deduplicated. Codex history is not used to create synthetic completed rows.

## Gatekeeper blocks the downloaded app

Community builds may be ad-hoc signed. Right-click the app in Finder, choose Open, then confirm Open. Do not disable Gatekeeper system-wide.
