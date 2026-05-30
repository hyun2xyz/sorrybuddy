#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DESKTOP="${DESKTOP_DIR:-$HOME/Desktop}"
PASSWORD_FILE="${ENCRYPTED_DMG_PASSWORD_FILE:-$DESKTOP/SorryBuddy-$VERSION-encrypted-password.txt}"
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-0}"

mkdir -p "$DESKTOP"

if [[ ! -e "$PASSWORD_FILE" ]]; then
    openssl rand -base64 32 > "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"
fi

export ENCRYPTED_DMG_PASSWORD_FILE="$PASSWORD_FILE"

APP_PATH="$("$ROOT/scripts/package-app.sh" | tail -n 1)"

if [[ "$SKIP_NOTARIZATION" != "1" && -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
    "$ROOT/scripts/notarize-app.sh" "$APP_PATH" >/dev/null
fi

DMG_PATH="$(APP_PATH_OVERRIDE="$APP_PATH" "$ROOT/scripts/package-dmg.sh" | tail -n 1)"
ENCRYPTED_DMG_PATH="$(APP_PATH_OVERRIDE="$APP_PATH" "$ROOT/scripts/package-encrypted-dmg.sh" | tail -n 1)"
PKG_PATH="$(APP_PATH_OVERRIDE="$APP_PATH" "$ROOT/scripts/package-pkg.sh" | tail -n 1)"
CHECKSUMS_PATH="$("$ROOT/scripts/checksums.sh" | tail -n 1)"

cp -f "$DMG_PATH" "$DESKTOP/$(basename "$DMG_PATH")"
cp -f "$ENCRYPTED_DMG_PATH" "$DESKTOP/$(basename "$ENCRYPTED_DMG_PATH")"
cp -f "$PKG_PATH" "$DESKTOP/$(basename "$PKG_PATH")"
cp -f "$CHECKSUMS_PATH" "$DESKTOP/$(basename "$CHECKSUMS_PATH")"

ENCRYPTED_DMG="$DESKTOP/$(basename "$ENCRYPTED_DMG_PATH")" \
    "$ROOT/scripts/verify-distribution.sh" "$DESKTOP/$(basename "$DMG_PATH")"

printf 'Artifacts:\n'
printf '  %s\n' "$DESKTOP/$(basename "$DMG_PATH")"
printf '  %s\n' "$DESKTOP/$(basename "$ENCRYPTED_DMG_PATH")"
printf '  %s\n' "$DESKTOP/$(basename "$PKG_PATH")"
printf '  %s\n' "$DESKTOP/$(basename "$CHECKSUMS_PATH")"
printf 'Password file:\n'
printf '  %s\n' "$PASSWORD_FILE"
