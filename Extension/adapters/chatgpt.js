globalThis.AIProgressHUDAdapters.chatgpt = {
  hosts: ["chatgpt.com"],
  stop: ['button[data-testid="stop-button"]', 'button[aria-label*="Stop"]', 'button[aria-label*="停止"]'],
  send: ['button[data-testid="send-button"]', 'button[aria-label*="Send"]', 'button[aria-label*="发送"]'],
  error: ['[data-testid="conversation-turn-error"]']
};
