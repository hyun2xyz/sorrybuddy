#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DIST="$ROOT/dist"
STAGING="$ROOT/.build/encrypted-dmg-root"
DMG="$DIST/SorryBuddy-$VERSION-encrypted.dmg"

password=""
if [[ -n "${ENCRYPTED_DMG_PASSWORD_FILE:-}" ]]; then
    password="$(cat "$ENCRYPTED_DMG_PASSWORD_FILE")"
elif [[ -n "${ENCRYPTED_DMG_PASSWORD:-}" ]]; then
    password="$ENCRYPTED_DMG_PASSWORD"
else
    cat >&2 <<'USAGE'
Set ENCRYPTED_DMG_PASSWORD or ENCRYPTED_DMG_PASSWORD_FILE before running.

Example:
  ENCRYPTED_DMG_PASSWORD_FILE="$HOME/Desktop/SorryBuddy.password.txt" ./scripts/package-encrypted-dmg.sh
USAGE
    exit 2
fi

if [[ ${#password} -lt 12 ]]; then
    echo "Encrypted DMG password must be at least 12 characters." >&2
    exit 2
fi

APP_PATH="${APP_PATH_OVERRIDE:-}"
if [[ -z "$APP_PATH" ]]; then
    APP_PATH="$("$ROOT/scripts/package-app.sh" | tail -n 1)"
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "App bundle not found: $APP_PATH" >&2
    exit 1
fi

rm -rf "$STAGING"
mkdir -p "$STAGING"
mkdir -p "$DIST"

ditto --norsrc --noextattr "$APP_PATH" "$STAGING/SorryBuddy.app"
ln -s /Applications "$STAGING/Applications"
find "$STAGING" -name '._*' -delete
xattr -cr "$STAGING" 2>/dev/null || true

rm -f "$DMG"
printf '%s' "$password" | hdiutil create \
    -volname "SorryBuddy" \
    -fs HFS+ \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    -encryption AES-256 \
    -stdinpass \
    "$DMG" >/dev/null

printf '%s' "$password" | hdiutil verify -stdinpass "$DMG" >/dev/null
hdiutil isencrypted "$DMG" | grep -qi 'encrypted'

DMG_SIGN_IDENTITY="${DMG_SIGN_IDENTITY:-${CODESIGN_IDENTITY:-}}"
if [[ -n "$DMG_SIGN_IDENTITY" && "$DMG_SIGN_IDENTITY" != "-" ]]; then
    codesign --force --sign "$DMG_SIGN_IDENTITY" --timestamp "$DMG"
    codesign --verify --verbose=2 "$DMG" >/dev/null
fi

echo "$DMG"
