# Changelog

All notable changes follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) principles.

## Unreleased

### Added

- Full installation guide, support matrix, and FAQ for GitHub visitors and first-time users.
- Clearer README positioning for the local bridge, provider toggles, and one-click return behavior.

### Changed

- Documentation now uses **Standby / 待命** instead of “Waiting” for idle AI surfaces.

## 0.3.0 — 2026-07-12

### Added

- GitHub-ready English and Chinese documentation, visual hero, CI, release automation, contribution guides, security policy, and issue templates.
- Branded app icon and bundled Chromium extension.
- Quick Setup diagnostics in the settings window.
- Clearly labeled Demo Mode with five providers and parallel Codex tasks.
- Clear WEB / APP / TASK source badges in the HUD.

### Changed

- Active and blocked tasks now sort ahead of completed and idle tasks.
- Long-running timers use `h:mm:ss` formatting.

## 0.2.0 — 2026-07-11

### Added

- ChatGPT, Claude, DeepSeek, and Yuanbao Chromium adapters.
- ChatGPT, Claude, and Yuanbao desktop detection through Accessibility.
- Parallel Codex thread detection using local thread IDs and titles.
- Authenticated localhost bridge, edge-snapping HUD, task grouping, and manual state fallback.
- Single-instance protection and actionable connection diagnostics.

### Fixed

- Settings and quit buttons now execute their intended actions.
- Codex timers use the current activity cluster instead of the full thread lifetime.
- Existing AI tabs are injected when the extension is installed or paired.
