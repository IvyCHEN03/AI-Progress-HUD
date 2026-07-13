globalThis.AIProgressHUDAdapters.yuanbao = {
  hosts: ["yuanbao.tencent.com"],
  title: ['[class*="conversation"][class*="active"]', '[class*="history"][class*="active"]', 'a[aria-current="page"]'],
  stop: ['button[aria-label*="停止"]', '[class*="stop-btn"]', '[class*="stopBtn"]'],
  send: ['button[aria-label*="发送"]', '[class*="send-btn"]'],
  error: ['[class*="error"]']
};
