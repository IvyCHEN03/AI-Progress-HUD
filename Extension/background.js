const ENDPOINT = "http://127.0.0.1:17321";
const AI_URLS = [
  "https://chatgpt.com/*",
  "https://claude.ai/*",
  "https://yuanbao.tencent.com/*",
  "https://chat.deepseek.com/*"
];

async function token() {
  return (await chrome.storage.local.get("pairingToken")).pairingToken || "";
}

chrome.runtime.onMessage.addListener((message, sender) => {
  if (message?.kind !== "ai-progress-event" || !sender.tab?.id) return;
  token().then(pairingToken => {
    if (!pairingToken) return;
    fetch(`${ENDPOINT}/event`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        ...message.payload,
        token: pairingToken,
        tabId: sender.tab.id,
        windowId: sender.tab.windowId,
        pageTitle: message.payload.pageTitle || sender.tab.title
      })
    }).catch(() => {}).finally(pollCommands);
  });
});

chrome.tabs.onRemoved.addListener(async tabId => {
  const pairingToken = await token();
  if (!pairingToken) return;
  fetch(`${ENDPOINT}/event`, {
    method: "POST", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ type: "closed", token: pairingToken, tabId })
  }).catch(() => {});
});

chrome.action.onClicked.addListener(() => chrome.runtime.openOptionsPage());

async function injectOpenAITabs() {
  const tabs = await chrome.tabs.query({ url: AI_URLS });
  const files = [
    "adapters/registry.js", "adapters/chatgpt.js", "adapters/claude.js",
    "adapters/yuanbao.js", "adapters/deepseek.js", "content.js"
  ];
  for (const tab of tabs) {
    if (!tab.id) continue;
    await chrome.scripting.executeScript({ target: { tabId: tab.id }, files }).catch(() => {});
  }
}

chrome.runtime.onInstalled.addListener(injectOpenAITabs);
chrome.runtime.onStartup.addListener(injectOpenAITabs);
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.pairingToken?.newValue) injectOpenAITabs();
});

async function pollCommands() {
  const pairingToken = await token();
  if (!pairingToken) return;
  try {
    const response = await fetch(`${ENDPOINT}/commands?token=${encodeURIComponent(pairingToken)}`);
    const commands = await response.json();
    for (const command of commands) {
      if (command.windowId != null) await chrome.windows.update(command.windowId, { focused: true }).catch(() => {});
      await chrome.tabs.update(command.tabId, { active: true }).catch(() => {});
    }
  } catch (_) {}
}

chrome.alarms.create("hud-poll", { periodInMinutes: 0.5 });
chrome.alarms.onAlarm.addListener(pollCommands);
setInterval(pollCommands, 2000);
