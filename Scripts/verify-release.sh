#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

swift test
node --check Extension/background.js
node --check Extension/content.js
node --check Extension/options.js
plutil -lint BundleResources/Info.plist
python3 -m json.tool Extension/manifest.json >/dev/null
codesign --verify --deep --strict --verbose=2 "AI Progress HUD.app"

echo "Release verification passed"
