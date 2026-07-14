(() => {
  if (window.__aiProgressHUDInstalled) return;
  window.__aiProgressHUDInstalled = true;
  const host = location.hostname;
  const registry = globalThis.AIProgressHUDAdapters || {};
  const provider = Object.keys(registry).find(key => registry[key].hosts.includes(host));
  if (!provider) return;
  const adapters = registry[provider];

  let state = "idle";
  let startedAt = null;
  let lastChangedAt = Date.now();
  let lastMutationAt = 0;
  let generationExpected = false;

  const exists = selectors => selectors.some(selector => {
    try { return document.querySelector(selector) != null; } catch (_) { return false; }
  });

  function conversationTitle() {
    const currentPath = location.pathname.replace(/\/$/, "") || "/";
    if (provider === "chatgpt" && currentPath === "/") return "New chat";
    const exactLinks = [...document.querySelectorAll('a[href]')].filter(node => {
      try {
        const url = new URL(node.href, location.href);
        return url.origin === location.origin && (url.pathname.replace(/\/$/, "") || "/") === currentPath;
      } catch (_) { return false; }
    }).sort((left, right) => {
      const score = node =>
        (/^new chat$|^新对话$|^新聊天$/i.test((node.textContent || "").replace(/\s+/g, " ").trim()) ? 16 : 0) +
        (node.getAttribute("aria-current") === "page" ? 8 : 0) +
        (node.closest('nav, aside, [role="navigation"]') ? 4 : 0) +
        (node.getAttribute("data-active") === "true" ? 2 : 0);
      return score(right) - score(left);
    });
    for (const node of exactLinks) {
      const text = (node.textContent || node.getAttribute("aria-label") || "").replace(/\s+/g, " ").trim();
      if (text && text.length <= 240) return text;
    }
    for (const selector of adapters.title || []) {
      let nodes = [];
      try { nodes = [...document.querySelectorAll(selector)]; } catch (_) { continue; }
      for (const node of nodes) {
        const text = (node.textContent || node.getAttribute("aria-label") || "").replace(/\s+/g, " ").trim();
        if (text && text.length <= 240) return text;
      }
    }
    return document.title;
  }

  function attentionVisible() {
    const controls = [...document.querySelectorAll('button, [role="alert"], [role="dialog"]')].slice(-80);
    return controls.some(node => /captcha|verify|log in|sign in|rate limit|验证码|登录|验证|频率限制|稍后再试/i.test(node.innerText || node.getAttribute("aria-label") || ""));
  }

  function computeState() {
    if (attentionVisible()) return "attention";
    if (exists(adapters.error)) return "error";
    if (exists(adapters.stop)) return Date.now() - lastMutationAt < 1400 ? "streaming" : "thinking";
    if (generationExpected) {
      // A missing stop button is not enough to declare completion: some providers
      // hide it briefly while the answer is still streaming. Wait for a quiet DOM.
      if (Date.now() - lastMutationAt < 2600) return "streaming";
      return "completed";
    }
    return state === "completed" ? "completed" : "idle";
  }

  function emit(force = false) {
    const next = computeState();
    if (next !== state) {
      state = next;
      lastChangedAt = Date.now();
      if (state === "completed" || state === "error" || state === "attention") generationExpected = false;
    } else if (!force) return;
    chrome.runtime.sendMessage({ kind: "ai-progress-event", payload: {
      provider, pageTitle: conversationTitle(), state, startedAt,
      lastChangedAt, needsAttention: state === "attention"
    }}).catch(() => {});
  }

  function markStarted() {
    if (!generationExpected) startedAt = Date.now();
    generationExpected = true;
    state = "thinking";
    lastChangedAt = Date.now();
    emit(true);
  }

  document.addEventListener("click", event => {
    const button = event.target.closest("button");
    if (button && adapters.send.some(selector => { try { return button.matches(selector); } catch (_) { return false; } })) markStarted();
  }, true);
  document.addEventListener("keydown", event => {
    if (event.key === "Enter" && !event.shiftKey && event.target.closest('textarea,[contenteditable="true"]')) markStarted();
  }, true);

  const observer = new MutationObserver(mutations => {
    if (mutations.some(item => item.addedNodes.length || item.removedNodes.length || item.type === "characterData")) {
      lastMutationAt = Date.now();
      if (generationExpected || exists(adapters.stop)) emit();
    }
  });
  observer.observe(document.documentElement, { subtree: true, childList: true, characterData: true, attributes: true, attributeFilter: ["disabled", "aria-label"] });
  setInterval(() => emit(true), 5000);
  emit(true);
})();
