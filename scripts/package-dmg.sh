#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DIST="$ROOT/dist"
DMG="$DIST/SorryBuddy-$VERSION.dmg"

APP_PATH="${APP_PATH_OVERRIDE:-}"
if [[ -z "$APP_PATH" ]]; then
    APP_PATH="$("$ROOT/scripts/package-app.sh" | tail -n 1)"
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "App bundle not found: $APP_PATH" >&2
    exit 1
fi

mkdir -p "$DIST"

APP_PATH="$APP_PATH" DMG_PATH="$DMG" "$ROOT/scripts/build-dmg.sh" >/dev/null

DMG_SIGN_IDENTITY="${DMG_SIGN_IDENTITY:-${CODESIGN_IDENTITY:-}}"
if [[ -n "$DMG_SIGN_IDENTITY" && "$DMG_SIGN_IDENTITY" != "-" ]]; then
    codesign --force --sign "$DMG_SIGN_IDENTITY" --timestamp "$DMG"
    codesign --verify --verbose=2 "$DMG" >/dev/null
fi

echo "$DMG"
