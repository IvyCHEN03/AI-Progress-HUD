# Privacy model

AI Progress HUD is designed so that a useful progress indicator does not require a copy of your conversation.

## What leaves the Mac?

Nothing. The project contains no telemetry SDK, analytics endpoint, hosted service, account system, or update tracker.

## Browser events

The extension sends a small JSON event to localhost containing:

```text
provider, tabId, windowId, pageTitle, state,
startedAt, lastChangedAt, needsAttention
```

Prompt and response bodies are not part of the interface.

## Desktop apps

Accessibility inspection is limited to supported application processes. The monitor looks for window titles and control labels associated with generation, stopping, retrying, verification, and errors. The tree is processed in memory and discarded.

## Codex

Codex support selects thread IDs, titles, recency times, and activity timestamps from local databases. It does not select message payloads or rollout content.

## Persistence

UserDefaults stores appearance settings and a random pairing token. Task content and conversation bodies are not persisted.

## Threat model

- A normal webpage cannot authenticate to the local bridge because it does not know the extension token.
- A malicious local process running as the same user remains outside the protection boundary and may inspect other user data independently of this app.
- Accessibility permission is powerful; the project keeps its inspected app allowlist explicit and narrow.
