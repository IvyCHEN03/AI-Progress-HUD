const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const root = path.resolve(__dirname, "..");
const context = vm.createContext({});
for (const file of ["registry.js", "chatgpt.js", "claude.js", "yuanbao.js", "deepseek.js"]) {
  vm.runInContext(fs.readFileSync(path.join(root, "adapters", file), "utf8"), context, { filename: file });
}

const adapters = context.AIProgressHUDAdapters;
assert.deepEqual(Object.keys(adapters).sort(), ["chatgpt", "claude", "deepseek", "yuanbao"]);

const hosts = new Set();
for (const [provider, adapter] of Object.entries(adapters)) {
  assert.ok(adapter.hosts.length > 0, `${provider} needs a hostname`);
  assert.ok(adapter.title.length > 0, `${provider} needs conversation-title selectors`);
  assert.ok(adapter.stop.length > 0, `${provider} needs a stop selector`);
  assert.ok(adapter.send.length > 0, `${provider} needs a send selector`);
  assert.ok(adapter.error.length > 0, `${provider} needs an error selector`);
  for (const host of adapter.hosts) {
    assert.equal(hosts.has(host), false, `${host} belongs to more than one provider`);
    hosts.add(host);
  }
}

console.log(`Validated ${Object.keys(adapters).length} provider adapters.`);
