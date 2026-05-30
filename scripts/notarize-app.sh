#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
APP="${1:-$ROOT/.build/release/SorryBuddy.app}"
PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"
ZIP="$ROOT/dist/SorryBuddy-$VERSION-notary.zip"

if [[ ! -d "$APP" ]]; then
    echo "App bundle not found: $APP" >&2
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
  NOTARY_KEYCHAIN_PROFILE=sorrybuddy-notary ./scripts/notarize-app.sh
USAGE
    exit 2
fi

mkdir -p "$ROOT/dist"
rm -f "$ZIP"
ditto -c -k --keepParent --norsrc --noextattr "$APP" "$ZIP"

xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl -a -vv --type exec "$APP"

echo "$APP"
