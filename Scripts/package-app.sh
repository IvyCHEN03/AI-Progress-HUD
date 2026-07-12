#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/AI Progress HUD.app"
CONTENTS_DIR="$APP_DIR/Contents"

cd "$ROOT_DIR"
swift build -c release
swift "$ROOT_DIR/Scripts/generate-icon.swift"
rm -rf "$APP_DIR"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp "$ROOT_DIR/.build/release/AIProgressHUD" "$CONTENTS_DIR/MacOS/AIProgressHUD"
chmod +x "$CONTENTS_DIR/MacOS/AIProgressHUD"
cp "$ROOT_DIR/BundleResources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/BundleResources/AIProgressHUD.icns" "$CONTENTS_DIR/Resources/AIProgressHUD.icns"
cp -R "$ROOT_DIR/Extension" "$CONTENTS_DIR/Resources/Extension"
printf "APPL????" > "$CONTENTS_DIR/PkgInfo"
codesign --force --deep --sign - "$APP_DIR"
echo "Built $APP_DIR"
