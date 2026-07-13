globalThis.AIProgressHUDAdapters.claude = {
  hosts: ["claude.ai"],
  title: ['nav a[href^="/chat/"][aria-current="page"]', 'a[href^="/chat/"][aria-current="page"]', '[data-testid*="conversation"][aria-current="page"]'],
  stop: ['button[aria-label*="Stop"]', 'button[aria-label*="停止"]', 'button[data-testid*="stop"]'],
  send: ['button[aria-label*="Send"]', 'button[aria-label*="发送"]', 'button[data-testid*="send"]'],
  error: ['[data-testid*="error"]']
};
