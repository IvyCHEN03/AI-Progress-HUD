globalThis.AIProgressHUDAdapters.chatgpt = {
  hosts: ["chatgpt.com", "chat.openai.com"],
  title: ['nav a[href^="/c/"][aria-current="page"]', 'nav a[href^="/c/"][data-active="true"]', 'a[href^="/c/"][aria-current="page"]'],
  stop: ['button[data-testid="stop-button"]', 'button[aria-label*="Stop"]', 'button[aria-label*="停止"]'],
  send: ['button[data-testid="send-button"]', 'button[aria-label*="Send"]', 'button[aria-label*="发送"]'],
  error: ['[data-testid="conversation-turn-error"]']
};
