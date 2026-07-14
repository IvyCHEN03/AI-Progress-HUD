# Chromium bridge

The extension converts provider-specific page controls into the shared HUD lifecycle without sending conversation content.

## Adapter layout

Each file under `adapters/` registers one configuration:

```js
globalThis.AIProgressHUDAdapters.example = {
  hosts: ["example.ai"],
  stop: ['button[aria-label="Stop"]'],
  send: ['button[aria-label="Send"]'],
  error: ['[role="alert"]']
};
```

Add the file to both `manifest.json` and the injection list in `background.js`, then extend `tests/adapters.test.js`.

Prefer stable `data-testid` and ARIA attributes. Avoid hashed CSS class names. Never add selectors or code that copies prompt/response containers into the event payload.

Run:

```bash
node Extension/tests/adapters.test.js
```

For a full scenario checklist, see [CONTRIBUTING.md](../CONTRIBUTING.md).
