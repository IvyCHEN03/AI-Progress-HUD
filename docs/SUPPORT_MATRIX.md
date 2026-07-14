# Support matrix

AI Progress HUD reports lifecycle state and elapsed time. It does not estimate a real completion percentage.

## Provider support

| Provider | Surface | Current support | Return behavior | Notes |
|---|---|---|---|---|
| ChatGPT | Chromium webpage | Stable adapter | Activates exact tab | Reload extension after updating adapter code. |
| ChatGPT | macOS desktop app | App presence + best-effort controls | Activates app | State depends on accessible Stop/Retry/Verify controls. |
| Claude | Chromium webpage | Stable adapter | Activates exact tab | Website DOM changes may require selector updates. |
| Claude | macOS desktop app | App presence + best-effort controls | Activates app | Requires Accessibility permission. |
| Codex | macOS desktop app | Local thread metadata + activity logs | Activates Codex and best-effort selects matching task | Only main user tasks are shown by default; internal subagents are deduplicated away. |
| DeepSeek | Chromium webpage | Stable adapter | Activates exact tab | Desktop app detection is experimental. |
| Yuanbao | Chromium webpage | Stable adapter | Activates exact tab | zh-CN UI labels are prioritized. |
| Yuanbao | macOS desktop app | Best-effort controls | Activates app | Requires Accessibility permission. |
| 灵感悬浮球 | macOS desktop app | App presence | Activates app | Shown as a desktop tool rather than an AI generation task. |

## State semantics

| State | Meaning | Typical source signal |
|---|---|---|
| Standby / 待命 | Surface exists but is not generating | Desktop app is running; no active generation control found |
| Thinking / 思考中 | Request accepted, output not yet streaming | Recent submit event, recent Codex recency update |
| Streaming / 输出中 | Output or task activity is changing | Stop button, DOM mutation, Codex stream/http activity |
| Completed / 已完成 | A new result is ready | Browser generation ended and content is stable |
| Needs action / 需操作 | User intervention required | Login, CAPTCHA, rate limit, approval, or verification control |
| Error / 异常 | Provider reported failure | Error banner, failed generation, network error |
| Disconnected / 失联 | Source stopped heartbeating | Extension/app stopped reporting |

## Known limitations

- Safari is not supported yet.
- Website adapters can break when providers ship DOM changes.
- Desktop state detection is best-effort because each app exposes different Accessibility labels.
- Codex direct task navigation is best-effort. If a private URL scheme becomes stable, it can replace Accessibility-based selection.
- The HUD intentionally avoids prompt and response bodies, so it cannot infer semantic task completion.

## Adapter health checklist

When reporting a broken adapter, include:

- provider and surface
- browser/app version
- locale
- expected state and observed HUD state
- a screenshot with conversation/account content redacted
- whether reload/re-pair/restart changed anything

