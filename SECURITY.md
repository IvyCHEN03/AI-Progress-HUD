# Security and privacy policy

AI Progress HUD observes AI applications, so privacy boundaries are part of the product—not documentation afterthoughts.

## Data that may be processed locally

- Provider name
- Browser tab or local thread identifier
- Window or tab title
- Lifecycle state
- Start, update, and heartbeat timestamps

## Data that must never be transmitted or persisted

- Prompt text
- Response text
- Uploaded files
- Cookies, session tokens, or API keys
- Browser history outside supported AI tabs
- Full Accessibility trees

## Local bridge

- Listens on `127.0.0.1:17321` only
- Requires a random per-install pairing token
- Rejects unauthenticated events and activation commands
- Does not expose an internet-facing service

## Permissions

Accessibility permission is used only for supported desktop AI apps. The monitor extracts a task title and recognized control labels such as Stop, Retry, or Verify. It does not persist the inspected tree.

Codex monitoring reads local metadata from the Codex thread and activity databases. SQL selects IDs, titles, and event timestamps only.

## Reporting a vulnerability

Until a repository security advisory channel is configured, contact the maintainer privately through the email listed on their GitHub profile. Include:

- affected version and macOS version
- minimal reproduction steps
- expected versus observed data exposure
- whether the issue is exploitable by a normal webpage or requires local access

Please allow a reasonable remediation window before public disclosure.
