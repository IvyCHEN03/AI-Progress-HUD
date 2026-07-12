# Product roadmap

## North star

Help people running several AI tasks answer three questions without context switching:

1. **Who is still working?**
2. **Which exact task is it?**
3. **Where does my attention belong next?**

North-star metric: **weekly completed tasks opened from the HUD**.

Guardrail metrics: state accuracy, false-completion rate, time-to-first-task, reconnect time, CPU usage, and zero privacy regressions.

## Positioning and moat

The market is filling with monitors for coding-agent CLIs. AI Progress HUD should not become another generic “agent pulse” clone.

Our wedge is **all AI work, not only coding**:

- consumer AI webpages plus native clients
- research, writing, analysis, and coding workflows
- browser tabs plus desktop windows plus native parallel Codex threads
- task identity and attention routing rather than token quota dashboards
- no hooks required for the first supported providers

The durable moat is a community-maintained adapter library paired with a strict local privacy contract.

## P0 — Trustworthy daily driver

- [x] Authenticated localhost bridge and single-instance protection
- [x] ChatGPT, Claude, DeepSeek, and Yuanbao Chromium adapters
- [x] ChatGPT, Claude, and Yuanbao desktop detection
- [x] Parallel Codex threads keyed by thread ID and title
- [x] Actionable connection diagnostics and permission fallback
- [x] WEB / APP / TASK identity badges and honest elapsed time
- [x] Double-clickable macOS package with bundled extension
- [x] CI, release artifacts, privacy policy, issue templates, and contributor docs
- [ ] Notarized universal macOS release with stable Accessibility identity
- [ ] Automated end-to-end provider state fixtures

## P1 — Reliable attention router

- Versioned provider adapters with a visible health/self-test result
- “Recently completed” inbox retained for 30 minutes
- Completion deduplication across reconnects and app restarts
- Direct Codex thread navigation instead of app-only activation
- Per-task pin, mute, rename, and project grouping
- Optional notifications: visual only, macOS notification, or focus-mode digest
- Menu bar summary such as `2 running · 1 ready`
- CPU and memory budget displayed in diagnostics
- Accessibility labels, keyboard navigation, VoiceOver audit, and reduced-motion mode

Exit criteria:

- three parallel tasks from one provider remain correctly separated
- app/browser restart recovers live state within 15 seconds
- false completion rate under 2% in the maintained scenario suite
- no unexplained blank state

## P2 — Community platform

- Adapter SDK with fixtures, selector inspector, and contributor test harness
- Safari Web Extension
- Claude Code, Gemini CLI, Cursor, Copilot, OpenCode, and additional desktop clients
- Local task timeline and per-provider reliability metrics
- Optional history-based duration ranges clearly labeled as estimates
- Project view grouping related tasks across providers
- Local URL scheme and Shortcuts/Raycast actions
- Signed auto-update channel and Homebrew Cask

## Deliberate non-goals

- Reading or summarizing conversation bodies
- A hosted account or analytics backend
- Fabricated deterministic progress percentages
- Becoming another AI chat client
- Requiring users to route prompts through this app

## Release gates

- Five providers can run simultaneously without task identity collisions.
- Every failure is actionable: permission, adapter breakage, token mismatch, or heartbeat loss.
- Prompt and response text never appear in network payloads, logs, or persisted state.
- Release artifacts include checksums, changelog, supported-version matrix, and rollback instructions.
- README quick start is reproducible by a new user in under three minutes.
