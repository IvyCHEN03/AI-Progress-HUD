# FAQ

## Is this a real progress percentage?

No. AI providers do not expose reliable remaining-time percentages. The HUD shows honest lifecycle state and elapsed time instead.

## Does it read my prompts or answers?

No. Browser events contain provider, tab/window identifiers, page title, lifecycle state, and timestamps. Desktop monitoring inspects supported app titles and controls in memory. Codex monitoring reads local metadata such as thread title and activity time.

## Why do desktop apps show Standby?

Standby means the app is open but no active generation control was detected. This is useful for routing back to running AI surfaces without pretending that work is happening.

## Why did a browser tab not appear?

Most often the extension was not injected into that tab. Reload the extension in `chrome://extensions`, refresh the AI tab, and confirm the pairing token still tests successfully.

## Why do Codex rows disappear?

Codex rows show recent main tasks, not every historical thread. Internal subagent threads are deduplicated away because they are implementation details and usually cannot be selected directly from the sidebar.

## Can clicking always jump to the exact Codex task?

Browser tabs can be activated exactly. Codex task selection is best-effort: the app activates Codex and uses Accessibility to find a matching sidebar task title. If Codex exposes a stable public URL scheme for thread navigation, the project should switch to that.

## Why does macOS ask for Accessibility again after rebuilding?

Accessibility permission is tied to the app identity and path. Rebuilt ad-hoc apps can look like new apps to macOS. Prefer installing one copy in `/Applications` and signing local builds with a stable certificate.

## Is there telemetry?

No. There is no hosted backend, analytics SDK, tracking pixel, or account system.

## Can I add another AI provider?

Yes. Add a provider adapter under `Extension/adapters/`, update the registry and tests, and document the surface in `docs/SUPPORT_MATRIX.md`.

