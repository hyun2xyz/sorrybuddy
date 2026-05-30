#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
APP="$ROOT/.build/release/SorryBuddy.app"
DMG="${1:-$ROOT/dist/SorryBuddy-$VERSION.dmg}"
ENCRYPTED_DMG="${ENCRYPTED_DMG:-$ROOT/dist/SorryBuddy-$VERSION-encrypted.dmg}"
REQUIRE_DEVELOPER_ID="${REQUIRE_DEVELOPER_ID:-0}"

failures=0
warnings=0

pass() {
    printf 'PASS %s\n' "$1"
}

warn() {
    warnings=$((warnings + 1))
    printf 'WARN %s\n' "$1" >&2
}

fail() {
    failures=$((failures + 1))
    printf 'FAIL %s\n' "$1" >&2
}

require_file() {
    if [[ -e "$1" ]]; then
        pass "$2"
    else
        fail "$2 missing: $1"
    fi
}

cd "$ROOT"

plutil -lint Packaging/Info.plist >/dev/null && pass "Info.plist is valid"

plist_version="$(plutil -extract CFBundleShortVersionString raw Packaging/Info.plist)"
if [[ "$plist_version" == "$VERSION" ]]; then
    pass "VERSION matches Info.plist ($VERSION)"
else
    fail "VERSION ($VERSION) does not match Info.plist ($plist_version)"
fi

if plutil -p Packaging/Info.plist | grep -q 'LSUIElement'; then
    fail "LSUIElement is present; app will be hidden from app switcher"
else
    pass "LSUIElement is absent"
fi

swift test >/dev/null && pass "swift test passed"

"$ROOT/scripts/package-app.sh" >/dev/null
require_file "$APP" "release app exists"

if codesign --verify --strict --verbose=2 "$APP" >/dev/null 2>&1; then
    pass "app code signature verifies"
else
    fail "app code signature verification failed"
fi

codesign_info="$(codesign -dv --verbose=4 "$APP" 2>&1 || true)"
if grep -q 'runtime' <<<"$codesign_info"; then
    pass "hardened runtime flag is present"
else
    fail "hardened runtime flag is missing"
fi

if grep -q 'TeamIdentifier=not set' <<<"$codesign_info"; then
    warn "Developer ID identity is not installed; current app is ad-hoc signed"
    if [[ "$REQUIRE_DEVELOPER_ID" == "1" ]]; then
        fail "Developer ID signature is required for public distribution"
    fi
else
    pass "app has a TeamIdentifier"
fi

if [[ -e "$DMG" ]]; then
    if hdiutil verify "$DMG" >/dev/null; then
        pass "DMG verifies: $DMG"
    else
        fail "DMG verification failed: $DMG"
    fi
else
    warn "DMG not found for verification: $DMG"
fi

if [[ -e "$ENCRYPTED_DMG" ]]; then
    if hdiutil isencrypted "$ENCRYPTED_DMG" | grep -qi 'encrypted'; then
        pass "encrypted DMG reports encrypted: $ENCRYPTED_DMG"
    else
        fail "encrypted DMG does not report encrypted: $ENCRYPTED_DMG"
    fi
else
    warn "encrypted DMG not found for verification: $ENCRYPTED_DMG"
fi

if spctl -a -vv --type exec "$APP" >/dev/null 2>&1; then
    pass "Gatekeeper accepts app"
else
    warn "Gatekeeper does not accept app yet; Developer ID signing and notarization are required"
    if [[ "$REQUIRE_DEVELOPER_ID" == "1" ]]; then
        fail "Gatekeeper acceptance is required for public distribution"
    fi
fi

if [[ "$failures" -gt 0 ]]; then
    printf 'Distribution verification finished with %d failure(s), %d warning(s).\n' "$failures" "$warnings" >&2
    exit 1
fi

printf 'Distribution verification finished with 0 failures, %d warning(s).\n' "$warnings"
