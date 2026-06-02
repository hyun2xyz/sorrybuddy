#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DESKTOP="${DESKTOP_DIR:-$HOME/Desktop}"
PASSWORD_FILE="${ENCRYPTED_DMG_PASSWORD_FILE:-$DESKTOP/SorryBuddy-$VERSION-encrypted-password.txt}"
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-0}"
INCLUDE_ENCRYPTED_DMG="${INCLUDE_ENCRYPTED_DMG:-0}"

mkdir -p "$DESKTOP"

APP_PATH="$("$ROOT/scripts/package-app.sh" | tail -n 1)"

if [[ "$SKIP_NOTARIZATION" != "1" && -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
    "$ROOT/scripts/notarize-app.sh" "$APP_PATH" >/dev/null
fi

DMG_PATH="$(APP_PATH_OVERRIDE="$APP_PATH" "$ROOT/scripts/package-dmg.sh" | tail -n 1)"
PKG_PATH="$(APP_PATH_OVERRIDE="$APP_PATH" "$ROOT/scripts/package-pkg.sh" | tail -n 1)"
CHECKSUMS_PATH="$("$ROOT/scripts/checksums.sh" | tail -n 1)"
ENCRYPTED_DMG_PATH=""

if [[ "$INCLUDE_ENCRYPTED_DMG" == "1" ]]; then
    if [[ ! -e "$PASSWORD_FILE" ]]; then
        openssl rand -base64 32 > "$PASSWORD_FILE"
        chmod 600 "$PASSWORD_FILE"
    fi

    export ENCRYPTED_DMG_PASSWORD_FILE="$PASSWORD_FILE"
    ENCRYPTED_DMG_PATH="$(APP_PATH_OVERRIDE="$APP_PATH" "$ROOT/scripts/package-encrypted-dmg.sh" | tail -n 1)"
    CHECKSUMS_PATH="$(INCLUDE_ENCRYPTED_DMG=1 "$ROOT/scripts/checksums.sh" | tail -n 1)"
fi

cp -f "$DMG_PATH" "$DESKTOP/$(basename "$DMG_PATH")"
cp -f "$PKG_PATH" "$DESKTOP/$(basename "$PKG_PATH")"
cp -f "$CHECKSUMS_PATH" "$DESKTOP/$(basename "$CHECKSUMS_PATH")"

swift "$ROOT/scripts/set-file-icon.swift" "$ROOT/Assets/AppIcon/SorryBuddy.icns" "$DESKTOP/$(basename "$DMG_PATH")" || true

if [[ -n "$ENCRYPTED_DMG_PATH" ]]; then
    cp -f "$ENCRYPTED_DMG_PATH" "$DESKTOP/$(basename "$ENCRYPTED_DMG_PATH")"
    swift "$ROOT/scripts/set-file-icon.swift" "$ROOT/Assets/AppIcon/SorryBuddy.icns" "$DESKTOP/$(basename "$ENCRYPTED_DMG_PATH")" || true
    ENCRYPTED_DMG="$DESKTOP/$(basename "$ENCRYPTED_DMG_PATH")" \
        VERIFY_ENCRYPTED_DMG=1 \
        "$ROOT/scripts/verify-distribution.sh" "$DESKTOP/$(basename "$DMG_PATH")"
else
    "$ROOT/scripts/verify-distribution.sh" "$DESKTOP/$(basename "$DMG_PATH")"
fi

printf 'Artifacts:\n'
printf '  %s\n' "$DESKTOP/$(basename "$DMG_PATH")"
printf '  %s\n' "$DESKTOP/$(basename "$PKG_PATH")"
printf '  %s\n' "$DESKTOP/$(basename "$CHECKSUMS_PATH")"

if [[ -n "$ENCRYPTED_DMG_PATH" ]]; then
    printf '  %s\n' "$DESKTOP/$(basename "$ENCRYPTED_DMG_PATH")"
    printf 'Password file:\n'
    printf '  %s\n' "$PASSWORD_FILE"
fi
