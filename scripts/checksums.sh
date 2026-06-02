#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DIST="$ROOT/dist"
OUT="${1:-$DIST/SHA256SUMS-$VERSION.txt}"

mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"

artifacts=(
    "SorryBuddy-$VERSION.dmg"
    "SorryBuddy-$VERSION.pkg"
)

if [[ "${INCLUDE_ENCRYPTED_DMG:-0}" == "1" ]]; then
    artifacts+=("SorryBuddy-$VERSION-encrypted.dmg")
fi

for artifact in "${artifacts[@]}"; do
    if [[ -e "$DIST/$artifact" ]]; then
        (cd "$DIST" && shasum -a 256 "$artifact") >> "$OUT"
    fi
done

if [[ ! -s "$OUT" ]]; then
    echo "No distribution artifacts found in $DIST" >&2
    exit 1
fi

echo "$OUT"
