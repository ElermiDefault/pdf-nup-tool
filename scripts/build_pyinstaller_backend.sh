#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v1.1.0}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUILD_DIR="$ROOT_DIR/build/pyinstaller-backend"
SAFE_ROOT="${TMPDIR:-/tmp}/pdf-nup-tool-pyinstaller-backend-src"
SAFE_BUILD_DIR="${TMPDIR:-/tmp}/pdf-nup-tool-pyinstaller-backend-build"
PYINSTALLER_DIST_DIR="$SAFE_BUILD_DIR/dist"
PYINSTALLER_CONFIG_DIR="$SAFE_BUILD_DIR/pyinstaller-config"
MPLCONFIGDIR="$SAFE_BUILD_DIR/matplotlib-config"
RUNTIME_NAME="PDF N-up Backend"
RUNTIME_DIR="$PYINSTALLER_DIST_DIR/$RUNTIME_NAME"
PACKAGE_NAME="pdf-nup-tool-${VERSION}-macos-backend-runtime"
STAGING_DIR="$DIST_DIR/$PACKAGE_NAME"
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

if ! "$PYTHON" -c "import PyInstaller" >/dev/null 2>&1; then
  die "PyInstaller is not installed. Install it in the active Python environment: python -m pip install pyinstaller"
fi

(
  cd "$ROOT_DIR/frontend"
  npm run build
)

rm -rf "$BUILD_DIR" "$STAGING_DIR"
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
  --onedir \
  --name "$RUNTIME_NAME" \
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

[[ -x "$RUNTIME_DIR/$RUNTIME_NAME" ]] || die "PyInstaller did not create $RUNTIME_DIR/$RUNTIME_NAME"

cp -R "$RUNTIME_DIR" "$STAGING_DIR/BackendRuntime"

echo "$STAGING_DIR/BackendRuntime"
