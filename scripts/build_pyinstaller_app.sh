#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v0.6.0}"
APP_VERSION="${VERSION#v}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUILD_DIR="$ROOT_DIR/build/pyinstaller"
SAFE_ROOT="${TMPDIR:-/tmp}/pdf-nup-tool-pyinstaller-src"
SAFE_BUILD_DIR="${TMPDIR:-/tmp}/pdf-nup-tool-pyinstaller-build"
PYINSTALLER_DIST_DIR="$SAFE_BUILD_DIR/dist"
PYINSTALLER_CONFIG_DIR="$SAFE_BUILD_DIR/pyinstaller-config"
MPLCONFIGDIR="$SAFE_BUILD_DIR/matplotlib-config"
APP_NAME="PDF N-up Tool"
PYINSTALLER_APP="$PYINSTALLER_DIST_DIR/${APP_NAME}.app"
PACKAGE_NAME="pdf-nup-tool-${VERSION}-macos-self-contained"
STAGING_DIR="$DIST_DIR/$PACKAGE_NAME"
ZIP_PATH="$DIST_DIR/$PACKAGE_NAME.zip"
ICON_PATH="$ROOT_DIR/${APP_NAME}.app/Contents/Resources/AppIcon.icns"
PYTHON="${PYTHON:-python3}"

die() {
  echo "Error: $*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

need_command npm
need_command "$PYTHON"
need_command codesign

if ! "$PYTHON" -c "import PyInstaller" >/dev/null 2>&1; then
  die "PyInstaller is not installed. Install it in the active Python environment: python -m pip install pyinstaller"
fi

(
  cd "$ROOT_DIR/frontend"
  npm run build
)

"$ROOT_DIR/scripts/build_macos_app.sh" "$APP_VERSION" >/dev/null
[[ -f "$ICON_PATH" ]] || die "Missing generated icon: $ICON_PATH"

rm -rf "$BUILD_DIR" "$STAGING_DIR" "$ZIP_PATH"
rm -rf "$SAFE_ROOT" "$SAFE_BUILD_DIR"
mkdir -p "$BUILD_DIR" "$STAGING_DIR" "$SAFE_BUILD_DIR" "$PYINSTALLER_CONFIG_DIR" "$MPLCONFIGDIR"
ln -s "$ROOT_DIR" "$SAFE_ROOT"

export PYINSTALLER_CONFIG_DIR
export MPLCONFIGDIR

PYINSTALLER_EXCLUDES=(
  "IPython"
  "PIL"
  "_tkinter"
  "black"
  "blib2to3"
  "jedi"
  "llvmlite"
  "lxml"
  "matplotlib"
  "numba"
  "numpy"
  "openpyxl"
  "pandas"
  "pygments"
  "scipy"
  "tkinter"
)

PYINSTALLER_EXCLUDE_ARGS=()
for module_name in "${PYINSTALLER_EXCLUDES[@]}"; do
  PYINSTALLER_EXCLUDE_ARGS+=(--exclude-module "$module_name")
done

"$PYTHON" -m PyInstaller \
  --noconfirm \
  --clean \
  --windowed \
  --name "$APP_NAME" \
  --osx-bundle-identifier "com.elermidefault.pdfnuptool" \
  --icon "$SAFE_ROOT/${APP_NAME}.app/Contents/Resources/AppIcon.icns" \
  --paths "$SAFE_ROOT/backend" \
  --distpath "$PYINSTALLER_DIST_DIR" \
  --workpath "$SAFE_BUILD_DIR/work" \
  --specpath "$SAFE_BUILD_DIR" \
  --add-data "$SAFE_ROOT/frontend/dist:frontend/dist" \
  --hidden-import "app.main" \
  --hidden-import "uvicorn.loops.auto" \
  --hidden-import "uvicorn.protocols.http.auto" \
  --hidden-import "uvicorn.protocols.websockets.auto" \
  --hidden-import "uvicorn.lifespan.on" \
  --hidden-import "fitz" \
  --hidden-import "pymupdf" \
  --collect-binaries "pymupdf" \
  "${PYINSTALLER_EXCLUDE_ARGS[@]}" \
  "$SAFE_ROOT/launcher/app_main.py"

[[ -d "$PYINSTALLER_APP" ]] || die "PyInstaller did not create $PYINSTALLER_APP"

"$PYTHON" - "$PYINSTALLER_APP/Contents/Info.plist" "$APP_VERSION" <<'PY'
from pathlib import Path
import plistlib
import sys

plist_path = Path(sys.argv[1])
version = sys.argv[2]
data = plistlib.loads(plist_path.read_bytes())
data["CFBundleDisplayName"] = "PDF N-up Tool"
data["CFBundleName"] = "PDF N-up Tool"
data["CFBundleShortVersionString"] = version
data["CFBundleVersion"] = version
data["NSHighResolutionCapable"] = True
plist_path.write_bytes(plistlib.dumps(data))
PY

codesign --force --deep --sign - "$PYINSTALLER_APP" >/dev/null

cp -R "$PYINSTALLER_APP" "$STAGING_DIR/${APP_NAME}.app"
cp "$ROOT_DIR/LICENSE" "$STAGING_DIR/LICENSE"

cat > "$STAGING_DIR/README.md" <<EOF
# PDF N-up Tool ${VERSION}

This is a self-contained macOS app preview.

## Run

Double-click:

\`\`\`text
PDF N-up Tool.app
\`\`\`

The app opens at:

\`\`\`text
http://127.0.0.1:8010
\`\`\`

Uploaded PDFs, thumbnails, logs, and exported files are stored locally under:

\`\`\`text
~/Library/Application Support/PDF N-up Tool
\`\`\`

This preview build is unsigned. If macOS blocks it, right-click the app and choose Open.
EOF

(
  cd "$DIST_DIR"
  zip -qry "$ZIP_PATH" "$PACKAGE_NAME"
)

echo "$ZIP_PATH"
