# GitHub launch and growth plan

Stars are an outcome of a product people understand, trust, install, and share. This plan avoids artificial star-chasing and focuses on durable adoption.

## Ideal users

### Primary: multi-AI knowledge worker

Runs research, writing, investment, strategy, or analysis tasks across ChatGPT, Claude, DeepSeek, Yuanbao, and Codex. The pain is repeated window switching and missed completions.

### Secondary: agent-heavy developer

Runs parallel Codex and browser research tasks but does not want to replace existing tools or configure a full orchestration platform.

### Contributor: adapter maintainer

Wants a small, testable way to add or repair one provider without learning the native app.

## Launch promise

> One glance tells you which AI task needs you next—across web, desktop, and parallel Codex threads. 100% local.

## Conversion funnel

1. **Repository impression → README engagement**
   - Hero image communicates the product in five seconds.
   - Supported providers appear above the fold.
   - “100% local / no telemetry” resolves trust immediately.
2. **README engagement → install**
   - Signed/notarized DMG is the highest priority remaining dependency.
   - Quick start stays under three steps.
   - GIF demonstrates two parallel tasks and a completed-task click-through.
3. **Install → first value**
   - Quick Setup shows exactly which connection is missing.
   - Demo mode can show the product before permissions are granted.
   - Time-to-first-real-task target: under three minutes.
4. **First value → star/share**
   - Ask for a star only after the user sees a completed task.
   - Make screenshots and a 15-second demo easy to share.
   - Publish transparent release notes and adapter health.

## Launch assets

- GitHub README hero and 15-second silent GIF
- One screenshot showing five providers and two parallel Codex tasks
- One architecture/privacy graphic
- Release DMG, ZIP, checksums, and notarization status
- 60-second setup video
- English and Chinese launch posts

## Distribution

- GitHub Releases and Homebrew Cask
- Hacker News Show HN: lead with the multi-AI context-switching problem and local architecture
- Reddit communities for macOS, productivity, ChatGPT, ClaudeAI, DeepSeek, and local-first software; tailor each post and avoid cross-post spam
- Product Hunt after notarized install and demo mode are ready
- Chinese channels: 少数派, V2EX, 即刻, 小红书/B站 demo, and AI productivity communities
- Submit to curated lists only after installation and privacy documentation are stable

## Community loops

- Label small provider-selector fixes as `good first issue`.
- Publish an adapter compatibility table for every release.
- Thank adapter contributors in release notes and README.
- Use Discussions for provider requests; Issues remain actionable bugs.
- Maintain a public “adapter broken” SLA target of 72 hours for major providers.

## Metrics

Track only public, aggregate GitHub signals—never add in-app telemetry.

- stars per unique release download
- release download → issue/discussion conversion
- README → release click-through using GitHub referrer data
- contributor count and time to first merged PR
- adapter breakage reports and median repair time
- releases per month and percentage with outside contributors

## 30-day sequence

### Week 1 — Release readiness

- notarized universal build, demo mode, GIF, clean install test, Homebrew draft

### Week 2 — Private beta

- 10–20 multi-AI users, capture setup friction, fix false states, collect permission-safe quotes

### Week 3 — GitHub launch

- v0.3 release, Show HN, targeted community posts, respond to every issue quickly

### Week 4 — Proof of maintenance

- ship v0.3.1 from real feedback, merge first external adapter fix, publish accuracy and privacy notes

## Anti-patterns

- Do not buy stars, run giveaways for stars, or spam unrelated communities.
- Do not claim exact progress or “supports every AI” without tests.
- Do not publish an unsigned binary without a prominent explanation.
- Do not collect telemetry to optimize GitHub metrics; use GitHub’s public repository data.
