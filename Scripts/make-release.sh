#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [[ $# -gt 0 ]]; then
    VERSION="$1"
else
    VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/BundleResources/Info.plist")"
fi
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$ROOT_DIR/AI Progress HUD.app"
ZIP_PATH="$DIST_DIR/AI-Progress-HUD-v$VERSION-macOS.zip"
DMG_PATH="$DIST_DIR/AI-Progress-HUD-v$VERSION-macOS.dmg"

"$ROOT_DIR/Scripts/package-app.sh"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
hdiutil create -volname "AI Progress HUD" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"

shasum -a 256 "$ZIP_PATH" "$DMG_PATH" > "$DIST_DIR/SHA256SUMS.txt"
echo "Release artifacts created in $DIST_DIR"
