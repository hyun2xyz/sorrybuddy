#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DMG="${1:-$ROOT/dist/SorryBuddy-$VERSION.dmg}"
PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"

if [[ ! -e "$DMG" ]]; then
    echo "DMG not found: $DMG" >&2
    exit 1
fi

if [[ -z "$PROFILE" ]]; then
    cat >&2 <<'USAGE'
Set NOTARY_KEYCHAIN_PROFILE before running.

One-time setup example:
  xcrun notarytool store-credentials sorrybuddy-notary \
    --apple-id you@example.com \
    --team-id TEAMID \
    --password app-specific-password

Run:
  NOTARY_KEYCHAIN_PROFILE=sorrybuddy-notary ./scripts/notarize-dmg.sh
USAGE
    exit 2
fi

xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"
spctl -a -vv --type open "$DMG"

echo "$DMG"
