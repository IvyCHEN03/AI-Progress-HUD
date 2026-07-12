# Release checklist

## Product quality

- [ ] Verify idle → thinking → streaming → completed for every supported provider.
- [ ] Run two parallel Codex threads and confirm distinct title/ID rows.
- [ ] Confirm click-to-return for browser, desktop, and Codex sources.
- [ ] Test duplicate app launch, browser restart, extension reload, sleep/wake, and permission removal.
- [ ] Confirm Demo Mode is visibly labeled and never mixed with real tasks.
- [ ] Run VoiceOver and reduced-transparency checks.

## Privacy and security

- [ ] Inspect browser event payloads; no prompt or response bodies.
- [ ] Confirm the bridge rejects a bad token and a non-loopback client.
- [ ] Confirm logs and UserDefaults contain no conversation content.
- [ ] Review dependency and GitHub Action versions.

## Build

- [ ] `make test`
- [ ] `make lint`
- [ ] `make release`
- [ ] Verify app code signature and notarization status.
- [ ] Test DMG and ZIP on a clean macOS user account.
- [ ] Verify Apple Silicon and Intel artifacts or label architecture accurately.
- [ ] Verify `SHA256SUMS.txt`.

## GitHub release

- [ ] Move changelog entries from Unreleased to the tagged version.
- [ ] Update screenshots/GIF if UI changed.
- [ ] Include supported-provider matrix and known adapter limitations.
- [ ] Include installation, upgrade, and rollback instructions.
- [ ] Create the tag only after the clean-machine install passes.
- [ ] Watch adapter issues and respond quickly for the first 72 hours.
