#!/usr/bin/env bash
set -euo pipefail

DMG="${1:?usage: verify-dmg-layout.sh <dmg>}"
MOUNT_LOG="$(mktemp)"
MOUNT_POINT=""
failures=0

mount_point_from_log() {
    awk '/\/Volumes\// {
        match($0, /\/Volumes\/.*/)
        print substr($0, RSTART)
        exit
    }' "$1"
}

cleanup() {
    if [[ -n "$MOUNT_POINT" ]] && mount | grep -q "on $MOUNT_POINT "; then
        hdiutil detach "$MOUNT_POINT" -quiet || true
    fi
    rm -f "$MOUNT_LOG"
}
trap cleanup EXIT

pass() {
    printf 'PASS %s\n' "$1"
}

fail() {
    failures=$((failures + 1))
    printf 'FAIL %s\n' "$1" >&2
}

if [[ -n "${DMG_PASSWORD:-}" ]]; then
    printf '%s' "$DMG_PASSWORD" | hdiutil attach -readonly -noautoopen -nobrowse -stdinpass "$DMG" > "$MOUNT_LOG"
else
    hdiutil attach -readonly -noautoopen -nobrowse "$DMG" > "$MOUNT_LOG"
fi

MOUNT_POINT="$(mount_point_from_log "$MOUNT_LOG")"
if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]; then
    cat "$MOUNT_LOG" >&2
    echo "Could not mount DMG: $DMG" >&2
    exit 1
fi

if [[ -d "$MOUNT_POINT/SorryBuddy.app" ]]; then
    pass "SorryBuddy.app is present"
else
    fail "SorryBuddy.app is missing"
fi

if [[ -L "$MOUNT_POINT/Applications" && "$(readlink "$MOUNT_POINT/Applications")" == "/Applications" ]]; then
    pass "Applications symlink points to /Applications"
else
    fail "Applications symlink is missing or wrong"
fi

if [[ -f "$MOUNT_POINT/.background/background.png" ]]; then
    pass "DMG background image is embedded"
else
    fail "DMG background image is missing"
fi

if GetFileInfo -a "$DMG" | grep -q 'C'; then
    pass "DMG file has a custom Finder icon"
else
    fail "DMG file custom Finder icon is missing"
fi

if [[ -f "$MOUNT_POINT/.VolumeIcon.icns" ]]; then
    pass "volume icon file is embedded"
else
    fail "volume icon file is missing"
fi

if GetFileInfo -a "$MOUNT_POINT" | grep -q 'C'; then
    pass "volume has custom icon attribute"
else
    fail "volume custom icon attribute is missing"
fi

if [[ -f "$MOUNT_POINT/.DS_Store" ]]; then
    pass "Finder layout metadata is embedded"
else
    fail "Finder layout metadata is missing"
fi

if [[ "$failures" -gt 0 ]]; then
    printf 'DMG layout verification finished with %d failure(s).\n' "$failures" >&2
    exit 1
fi

printf 'DMG layout verification finished with 0 failures.\n'
