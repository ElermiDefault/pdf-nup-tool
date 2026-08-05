#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v1.1.0}"
APP_VERSION="${VERSION#v}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUILD_DIR="$ROOT_DIR/build/native"
PACKAGE_NAME="pdf-nup-tool-${VERSION}-macos-native"
PACKAGE_DIR="$DIST_DIR/$PACKAGE_NAME"
APP_NAME="PDF N-up Tool"
APP_DIR="$PACKAGE_DIR/${APP_NAME}.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_SOURCE="$ROOT_DIR/assets/logo.png"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
ICON_PATH="$RESOURCES_DIR/AppIcon.icns"
BACKEND_RUNTIME="$DIST_DIR/pdf-nup-tool-${VERSION}-macos-backend-runtime/BackendRuntime"
SWIFT_SOURCES=(
  "$ROOT_DIR/native/macos/PDFNupToolApp.swift"
  "$ROOT_DIR/native/macos/main.swift"
)
EXECUTABLE_PATH="$MACOS_DIR/$APP_NAME"
PYTHON="${PYTHON:-python3}"

die() {
  echo "Error: $*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

need_command codesign
need_command ditto
need_command sips
need_command xcrun
need_command "$PYTHON"

[[ -f "$ICON_SOURCE" ]] || die "Missing icon source: $ICON_SOURCE"
for swift_source in "${SWIFT_SOURCES[@]}"; do
  [[ -f "$swift_source" ]] || die "Missing Swift source: $swift_source"
done

"$ROOT_DIR/scripts/build_pyinstaller_backend.sh" "$VERSION" >/dev/null
[[ -x "$BACKEND_RUNTIME/PDF N-up Backend" ]] || die "Missing backend runtime: $BACKEND_RUNTIME"

rm -rf "$PACKAGE_DIR" "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$ICONSET_DIR"

sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16.png" >/dev/null
sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32.png" >/dev/null
sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_64.png" >/dev/null
sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128.png" >/dev/null
sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256.png" >/dev/null
sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512.png" >/dev/null
sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_1024.png" >/dev/null

"$PYTHON" - "$ICONSET_DIR" "$ICON_PATH" <<'PY'
from pathlib import Path
import struct
import sys

iconset_dir = Path(sys.argv[1])
icon_path = Path(sys.argv[2])
entries = [
    ("icp4", iconset_dir / "icon_16.png"),
    ("icp5", iconset_dir / "icon_32.png"),
    ("icp6", iconset_dir / "icon_64.png"),
    ("ic07", iconset_dir / "icon_128.png"),
    ("ic08", iconset_dir / "icon_256.png"),
    ("ic09", iconset_dir / "icon_512.png"),
    ("ic10", iconset_dir / "icon_1024.png"),
]

chunks = []
for code, path in entries:
    data = path.read_bytes()
    chunks.append(code.encode("ascii") + struct.pack(">I", len(data) + 8) + data)

payload = b"".join(chunks)
icon_path.write_bytes(b"icns" + struct.pack(">I", len(payload) + 8) + payload)
PY

xcrun swiftc \
  -O \
  -framework Cocoa \
  -framework WebKit \
  -framework UniformTypeIdentifiers \
  "${SWIFT_SOURCES[@]}" \
  -o "$EXECUTABLE_PATH"

ditto "$BACKEND_RUNTIME" "$RESOURCES_DIR/BackendRuntime"

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>PDF N-up Tool</string>
  <key>CFBundleExecutable</key>
  <string>PDF N-up Tool</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>com.elermidefault.pdfnuptool</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>PDF N-up Tool</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${APP_VERSION}</string>
  <key>LSMinimumSystemVersion</key>
  <string>11.0</string>
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
  </dict>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$APP_DIR" >/dev/null
codesign --verify --deep --strict --verbose=1 "$APP_DIR" >/dev/null

echo "$APP_DIR"
