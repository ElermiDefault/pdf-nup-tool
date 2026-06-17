#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v1.0.0}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUILD_DIR="$ROOT_DIR/build/dmg"
APP_NAME="PDF N-up Tool"
APP_PACKAGE_NAME="pdf-nup-tool-${VERSION}-macos-self-contained"
APP_PACKAGE_DIR="$DIST_DIR/$APP_PACKAGE_NAME"
APP_PATH="$APP_PACKAGE_DIR/${APP_NAME}.app"
DMG_PACKAGE_NAME="pdf-nup-tool-${VERSION}-macos"
DMG_STAGING_DIR="$BUILD_DIR/$DMG_PACKAGE_NAME"
DMG_PATH="$DIST_DIR/$DMG_PACKAGE_NAME.dmg"

die() {
  echo "Error: $*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

need_command hdiutil
need_command ditto

"$ROOT_DIR/scripts/build_pyinstaller_app.sh" "$VERSION" >/dev/null
[[ -d "$APP_PATH" ]] || die "Missing built app: $APP_PATH"

rm -rf "$DMG_STAGING_DIR" "$DMG_PATH"
mkdir -p "$DMG_STAGING_DIR"

ditto "$APP_PATH" "$DMG_STAGING_DIR/${APP_NAME}.app"
ln -s /Applications "$DMG_STAGING_DIR/Applications"
cp "$ROOT_DIR/LICENSE" "$DMG_STAGING_DIR/LICENSE"

cat > "$DMG_STAGING_DIR/README.md" <<EOF
# PDF N-up Tool ${VERSION}

## Install

Drag \`PDF N-up Tool.app\` to \`Applications\`.

## Run

Open \`PDF N-up Tool.app\` from Applications.

The app opens:

\`\`\`text
http://127.0.0.1:8010
\`\`\`

Uploaded PDFs, thumbnails, logs, and exported files are stored locally under:

\`\`\`text
~/Library/Application Support/PDF N-up Tool
\`\`\`

## macOS Security Notice

This build is not signed with an Apple Developer ID and is not notarized.

On first launch, macOS may block the app. If that happens, right-click
\`PDF N-up Tool.app\` and choose \`Open\`.
EOF

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

hdiutil verify "$DMG_PATH" >/dev/null

echo "$DMG_PATH"
