# Contributing to AI Progress HUD

Thanks for helping make parallel AI work calmer.

## Best first contributions

- Repair a provider adapter after a website DOM change.
- Add selectors for another locale without reading message content.
- Add a reproducible state-transition test.
- Improve onboarding, accessibility, or localization.
- Validate a release on another Chromium browser or macOS version.

## Development setup

```bash
git clone <repository-url>
cd ai-progress-hud
make test
make lint
make package
```

Requirements: macOS 13+, Xcode Command Line Tools, Swift 6, and Node.js.

## Architecture rules

1. **Local-first is non-negotiable.** No telemetry, hosted backend, or third-party analytics.
2. **Never collect conversation bodies.** Provider adapters may inspect controls and transient page state, but outbound events must contain only provider, task identity, title, state, and timestamps.
3. **Do not invent progress percentages.** Use explicit lifecycle states and elapsed time.
4. **Keep adapters isolated.** A provider DOM change should affect one adapter, not the HUD core.
5. **Every failure must be actionable.** Prefer “extension not reporting—reload tab” over a silent empty screen.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for data flow and interfaces.

## Pull requests

- Keep changes focused and explain the user-visible outcome first.
- Add or update tests for state transitions and parsing behavior.
- Run `make test` and `make lint` before opening a PR.
- Include before/after screenshots for visual changes.
- Update `CHANGELOG.md` under **Unreleased**.

## Provider adapter checklist

- [ ] Idle page produces `idle`.
- [ ] Sending a request produces `thinking`.
- [ ] Active output produces `streaming`.
- [ ] Completion produces exactly one `completed` transition.
- [ ] Login, CAPTCHA, limit, and retry states map to `attention` or `error`.
- [ ] Closing a tab removes the correct task only.
- [ ] No prompt or response text is sent to localhost or written to disk.
- [ ] Non-English UI labels are covered where practical.

## Reporting security issues

Do not open a public issue for a privacy or security vulnerability. Follow [SECURITY.md](SECURITY.md).
