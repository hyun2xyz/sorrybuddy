#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/.build/release"
APP="$BUILD_DIR/SorryBuddy.app"

swift build -c release --package-path "$ROOT"

if [[ "$APP" == "$BUILD_DIR/SorryBuddy.app" ]]; then
    rm -rf "$APP"
fi

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp "$BUILD_DIR/SorryBuddy" "$APP/Contents/MacOS/SorryBuddy"
cp "$ROOT/Packaging/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Assets/AppIcon/SorryBuddy.icns" "$APP/Contents/Resources/SorryBuddy.icns"
cp "$ROOT/Assets/MenuBar/SorryBuddyMenuBar.png" "$APP/Contents/Resources/SorryBuddyMenuBar.png"
cp "$ROOT/Assets/MenuBar/SorryBuddyMenuBarTemplate.png" "$APP/Contents/Resources/SorryBuddyMenuBarTemplate.png"
chmod +x "$APP/Contents/MacOS/SorryBuddy"

find "$APP" -name '._*' -delete
xattr -cr "$APP" 2>/dev/null || true

if command -v strip >/dev/null 2>&1; then
    strip -x "$APP/Contents/MacOS/SorryBuddy" || true
fi

find "$APP" -type d -exec chmod 755 {} +
find "$APP" -type f -exec chmod 644 {} +
chmod 755 "$APP/Contents/MacOS/SorryBuddy"

SIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
SIGN_ARGS=(--force --options runtime --sign "$SIGN_IDENTITY")
if [[ "$SIGN_IDENTITY" != "-" ]]; then
    SIGN_ARGS+=(--timestamp)
fi

codesign "${SIGN_ARGS[@]}" "$APP"
codesign --verify --strict --verbose=2 "$APP" >/dev/null

echo "$APP"
