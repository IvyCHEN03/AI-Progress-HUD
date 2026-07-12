globalThis.AIProgressHUDAdapters.claude = {
  hosts: ["claude.ai"],
  stop: ['button[aria-label*="Stop"]', 'button[aria-label*="停止"]', 'button[data-testid*="stop"]'],
  send: ['button[aria-label*="Send"]', 'button[aria-label*="发送"]', 'button[data-testid*="send"]'],
  error: ['[data-testid*="error"]']
};
