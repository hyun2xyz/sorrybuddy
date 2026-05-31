#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESKTOP="${DESKTOP_DIR:-$HOME/Desktop}"

DMG_PATH="$("$ROOT/scripts/package-dmg.sh" | tail -n 1)"
PKG_PATH="$("$ROOT/scripts/package-pkg.sh" | tail -n 1)"

mkdir -p "$DESKTOP"
cp -f "$DMG_PATH" "$DESKTOP/$(basename "$DMG_PATH")"
cp -f "$PKG_PATH" "$DESKTOP/$(basename "$PKG_PATH")"
swift "$ROOT/scripts/set-file-icon.swift" "$ROOT/Assets/AppIcon/SorryBuddy.icns" "$DESKTOP/$(basename "$DMG_PATH")" || true

shasum -a 256 "$DESKTOP/$(basename "$DMG_PATH")" "$DESKTOP/$(basename "$PKG_PATH")"
