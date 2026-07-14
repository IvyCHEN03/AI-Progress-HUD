const input = document.querySelector("#token");
const status = document.querySelector("#status");
chrome.storage.local.get("pairingToken").then(value => input.value = value.pairingToken || "");
document.querySelector("#save").addEventListener("click", async () => {
  const pairingToken = input.value.trim();
  if (!pairingToken) {
    status.textContent = "请先粘贴令牌";
    return;
  }
  await chrome.storage.local.set({ pairingToken });
  try {
    const response = await fetch(`http://127.0.0.1:17321/pair?token=${encodeURIComponent(pairingToken)}`);
    status.textContent = response.ok ? "已配对，正在同步已打开页面" : "令牌不匹配";
  } catch (_) { status.textContent = "请先启动 macOS App"; }
});
