#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/.build/release"
APP="$BUILD_DIR/SorryBuddy.app"

swift build -c release --package-path "$ROOT"

if [[ "$APP" == "$BUILD_DIR/SorryBuddy.app" ]]; then
    rm -rf "$APP"
fi

mkdir -p "$APP/Contents/MacOS"
cp "$BUILD_DIR/SorryBuddy" "$APP/Contents/MacOS/SorryBuddy"
cp "$ROOT/Packaging/Info.plist" "$APP/Contents/Info.plist"
chmod +x "$APP/Contents/MacOS/SorryBuddy"

codesign --force --deep --sign - "$APP"

echo "$APP"
