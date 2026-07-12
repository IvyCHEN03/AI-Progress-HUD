# Troubleshooting

## The HUD is empty

Open settings and inspect **Quick setup**:

- **Local bridge unavailable** — quit duplicate copies of the app and relaunch the copy you intend to use.
- **Browser extension has no heartbeat** — save the pairing token, reload the extension, and refresh supported tabs.
- **Desktop permission missing** — enable the exact running app copy under System Settings → Privacy & Security → Accessibility.

## The extension says connected but no task appears

Confirm the options page shows version `v0.2` or later. In `chrome://extensions`, click Reload, then refresh the AI tab. The extension only runs on supported hostnames.

## Accessibility is enabled but desktop apps still say permission required

macOS permissions are tied to a specific app signature. Remove stale copies of AI Progress HUD, remove the old Accessibility entry, add the final app from Applications, and relaunch it. Rebuilding an ad-hoc signed development copy changes its signature and can require permission again.

## A website changed and status is wrong

Open an **Adapter broken** issue. Include provider, browser version, locale, expected state, observed state, and a screenshot with conversation content redacted. Never post cookies or account tokens.

## Codex shows multiple rows

That is intentional: each parallel Codex thread receives its own task row and short thread ID. Recent completed threads remain visible briefly so results are not missed.

## Gatekeeper blocks the downloaded app

Community builds may be ad-hoc signed. Right-click the app in Finder, choose Open, then confirm Open. Do not disable Gatekeeper system-wide.
