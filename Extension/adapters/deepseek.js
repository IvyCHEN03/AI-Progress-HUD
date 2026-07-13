globalThis.AIProgressHUDAdapters.deepseek = {
  hosts: ["chat.deepseek.com"],
  title: ['a[href*="/chat/"][aria-current="page"]', '[class*="conversation"][class*="active"]', '[class*="history"][class*="active"]'],
  stop: ['button[aria-label*="停止"]', 'button[aria-label*="Stop"]', '[class*="stop"]'],
  send: ['button[aria-label*="发送"]', 'button[aria-label*="Send"]'],
  error: ['[class*="error"]']
};
