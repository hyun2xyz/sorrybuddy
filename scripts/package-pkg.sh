#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DIST="$ROOT/dist"
PKG="$DIST/SorryBuddy-$VERSION.pkg"
STAGING="$ROOT/.build/pkg-root"

APP_PATH="${APP_PATH_OVERRIDE:-}"
if [[ -z "$APP_PATH" ]]; then
    APP_PATH="$("$ROOT/scripts/package-app.sh" | tail -n 1)"
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "App bundle not found: $APP_PATH" >&2
    exit 1
fi

mkdir -p "$DIST"
rm -f "$PKG"
rm -rf "$STAGING"
mkdir -p "$STAGING/Applications"

ditto --norsrc --noextattr "$APP_PATH" "$STAGING/Applications/SorryBuddy.app"
find "$STAGING" -name '._*' -delete
xattr -cr "$STAGING" 2>/dev/null || true

PKG_ARGS=(
    --root "$STAGING"
    --install-location /
    --identifier xyz.hyun2.sorrybuddy
    --version "$VERSION"
    --filter '\.DS_Store$'
    --filter '(^|/)\.svn($|/)'
    --filter '(^|/)CVS($|/)'
    --filter '(^|/)\._'
)

if [[ -n "${INSTALLER_SIGN_IDENTITY:-}" ]]; then
    PKG_ARGS+=(--sign "$INSTALLER_SIGN_IDENTITY")
fi

pkgbuild "${PKG_ARGS[@]}" "$PKG" >/dev/null
pkgutil --payload-files "$PKG" >/dev/null

if [[ -n "${INSTALLER_SIGN_IDENTITY:-}" ]]; then
    pkgutil --check-signature "$PKG" >/dev/null
fi

echo "$PKG"
