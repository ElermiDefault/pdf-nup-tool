#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_VERSION="${1:-0.5.0}"
APP_NAME="PDF N-up Tool"
APP_DIR="$ROOT_DIR/${APP_NAME}.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_SOURCE="$ROOT_DIR/assets/logo.png"
ICONSET_DIR="$ROOT_DIR/tmp/app-icon.iconset"
ICON_PATH="$RESOURCES_DIR/AppIcon.icns"
EXECUTABLE_PATH="$MACOS_DIR/pdf-nup-tool"

die() {
  echo "Error: $*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

[[ -f "$ICON_SOURCE" ]] || die "Missing icon source: $ICON_SOURCE"
[[ -x "$ROOT_DIR/pdfnuptool" ]] || die "Missing executable launcher: $ROOT_DIR/pdfnuptool"

need_command sips
need_command python3

rm -rf "$APP_DIR" "$ICONSET_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$ICONSET_DIR"

sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16.png" >/dev/null
sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32.png" >/dev/null
sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_64.png" >/dev/null
sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128.png" >/dev/null
sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256.png" >/dev/null
sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512.png" >/dev/null
sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_1024.png" >/dev/null

python3 - "$ICONSET_DIR" "$ICON_PATH" <<'PY'
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
  <string>pdf-nup-tool</string>
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
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

cat > "$EXECUTABLE_PATH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT_DIR="$(cd "$APP_DIR/.." && pwd)"
LOG_DIR="$PROJECT_DIR/tmp"
LOG_FILE="$LOG_DIR/app-launcher.log"
PYTHON="$PROJECT_DIR/.venv/bin/python"

mkdir -p "$LOG_DIR"
cd "$PROJECT_DIR"

show_error() {
  local message="$1"
  echo "$message" >>"$LOG_FILE"
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display dialog \"$message\" buttons {\"OK\"} default button \"OK\" with title \"PDF N-up Tool\""
  fi
}

if [[ ! -x "$PYTHON" ]]; then
  show_error "Missing Python environment. Please run install.command first, then reopen PDF N-up Tool.app."
  exit 1
fi

exec "$PYTHON" "$PROJECT_DIR/pdfnuptool" >>"$LOG_FILE" 2>&1
EOF

chmod +x "$EXECUTABLE_PATH"

echo "$APP_DIR"
