#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DIST="$ROOT/dist"
STAGING="$ROOT/.build/dmg-root"
DMG="$DIST/SorryBuddy-$VERSION.dmg"

APP_PATH="$("$ROOT/scripts/package-app.sh" | tail -n 1)"

rm -rf "$STAGING"
mkdir -p "$STAGING"
mkdir -p "$DIST"

cp -R "$APP_PATH" "$STAGING/SorryBuddy.app"
ln -s /Applications "$STAGING/Applications"
find "$STAGING" -name '._*' -delete
xattr -cr "$STAGING" 2>/dev/null || true

rm -f "$DMG"
hdiutil create \
    -volname "SorryBuddy" \
    -fs HFS+ \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG" >/dev/null

hdiutil verify "$DMG" >/dev/null

DMG_SIGN_IDENTITY="${DMG_SIGN_IDENTITY:-${CODESIGN_IDENTITY:-}}"
if [[ -n "$DMG_SIGN_IDENTITY" && "$DMG_SIGN_IDENTITY" != "-" ]]; then
    codesign --force --sign "$DMG_SIGN_IDENTITY" --timestamp "$DMG"
    codesign --verify --verbose=2 "$DMG" >/dev/null
fi

echo "$DMG"
