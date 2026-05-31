#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${APP_PATH:?APP_PATH is required}"
DMG_PATH="${DMG_PATH:?DMG_PATH is required}"
VOLUME_NAME="${DMG_VOLUME_NAME:-SorryBuddy}"
STAGING="${DMG_STAGING:-$ROOT/.build/dmg-layout-root}"
BACKGROUND="$STAGING/.background/background.png"
RW_DMG="$ROOT/.build/$(basename "${DMG_PATH%.dmg}")-rw.dmg"
ICON="$ROOT/Assets/AppIcon/SorryBuddy.icns"

mount_point_from_log() {
    awk '/\/Volumes\// {
        match($0, /\/Volumes\/.*/)
        print substr($0, RSTART)
        exit
    }' "$1"
}

if [[ ! -d "$APP_PATH" ]]; then
    echo "App bundle not found: $APP_PATH" >&2
    exit 1
fi

rm -rf "$STAGING"
rm -f "$RW_DMG" "$DMG_PATH"
mkdir -p "$STAGING/.background" "$(dirname "$DMG_PATH")"

ditto --norsrc --noextattr "$APP_PATH" "$STAGING/SorryBuddy.app"
ln -s /Applications "$STAGING/Applications"
cp "$ICON" "$STAGING/.VolumeIcon.icns"
swift "$ROOT/scripts/create-dmg-background.swift" "$BACKGROUND"

find "$STAGING" -name '._*' -delete
xattr -cr "$STAGING" 2>/dev/null || true

hdiutil create \
    -volname "$VOLUME_NAME" \
    -fs HFS+ \
    -srcfolder "$STAGING" \
    -ov \
    -format UDRW \
    "$RW_DMG" >/dev/null

MOUNT_LOG="$(mktemp)"
MOUNT_POINT=""
cleanup() {
    if [[ -n "$MOUNT_POINT" ]] && mount | grep -q "on $MOUNT_POINT "; then
        hdiutil detach "$MOUNT_POINT" -quiet || true
    fi
    rm -f "$MOUNT_LOG"
}
trap cleanup EXIT

while IFS= read -r mounted_volume; do
    hdiutil detach "$mounted_volume" -quiet || true
done < <(mount | sed -n "s#^.* on \\(/Volumes/$VOLUME_NAME[^)]*\\) (.*#\\1#p")

hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG" > "$MOUNT_LOG"
MOUNT_POINT="$(mount_point_from_log "$MOUNT_LOG")"
if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]; then
    echo "Could not mount temporary DMG" >&2
    cat "$MOUNT_LOG" >&2
    exit 1
fi

osascript <<APPLESCRIPT
set backgroundImage to POSIX file "$MOUNT_POINT/.background/background.png" as alias
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {120, 120, 800, 510}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 112
        set text size of viewOptions to 14
        set background picture of viewOptions to backgroundImage
        set position of item "SorryBuddy.app" of container window to {155, 158}
        set position of item "Applications" of container window to {525, 158}
        update without registering applications
        delay 0.4
        close
    end tell
end tell
APPLESCRIPT

cp "$ICON" "$MOUNT_POINT/.VolumeIcon.icns"
SetFile -a C "$MOUNT_POINT"
SetFile -a V "$MOUNT_POINT/.VolumeIcon.icns"
SetFile -a V "$MOUNT_POINT/.background"

sync
hdiutil detach "$MOUNT_POINT" -quiet
MOUNT_POINT=""

if [[ -n "${DMG_ENCRYPTION_PASSWORD:-}" ]]; then
    printf '%s' "$DMG_ENCRYPTION_PASSWORD" | hdiutil convert "$RW_DMG" \
        -format UDZO \
        -encryption AES-256 \
        -stdinpass \
        -o "$DMG_PATH" >/dev/null
    printf '%s' "$DMG_ENCRYPTION_PASSWORD" | hdiutil verify -stdinpass "$DMG_PATH" >/dev/null
    hdiutil isencrypted "$DMG_PATH" | grep -qi 'encrypted'
else
    hdiutil convert "$RW_DMG" -format UDZO -o "$DMG_PATH" >/dev/null
    hdiutil verify "$DMG_PATH" >/dev/null
fi

swift "$ROOT/scripts/set-file-icon.swift" "$ICON" "$DMG_PATH" || true
rm -f "$RW_DMG"

echo "$DMG_PATH"
