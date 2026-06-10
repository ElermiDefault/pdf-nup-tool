#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v0.5.0}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
PACKAGE_NAME="pdf-nup-tool-${VERSION}-macos-app-preview"
STAGING_DIR="$DIST_DIR/$PACKAGE_NAME"
ZIP_PATH="$DIST_DIR/$PACKAGE_NAME.zip"

rm -rf "$STAGING_DIR" "$ZIP_PATH"
mkdir -p "$STAGING_DIR"

(
  cd "$ROOT_DIR/frontend"
  npm run build
)

"$ROOT_DIR/scripts/build_macos_app.sh" "${VERSION#v}" >/dev/null

rsync -a "$ROOT_DIR/" "$STAGING_DIR/" \
  --exclude ".git/" \
  --exclude ".DS_Store" \
  --exclude ".venv/" \
  --exclude "__pycache__/" \
  --exclude "*.pyc" \
  --exclude "/dist/" \
  --exclude "frontend/node_modules/" \
  --exclude "tmp/*" \
  --exclude "output/exports/" \
  --exclude "output/*.pdf" \
  --exclude "samples/*.pdf"

mkdir -p "$STAGING_DIR/tmp" "$STAGING_DIR/output" "$STAGING_DIR/samples"
touch "$STAGING_DIR/tmp/.gitkeep" "$STAGING_DIR/output/.gitkeep" "$STAGING_DIR/samples/.gitkeep"
if [[ -f "$ROOT_DIR/tmp/README.md" ]]; then
  cp "$ROOT_DIR/tmp/README.md" "$STAGING_DIR/tmp/README.md"
fi

cat > "$STAGING_DIR/RELEASE_NOTES.md" <<EOF
# PDF N-up Tool ${VERSION}

This package is a macOS local app packaging preview.

## Requirements

- Python 3.10+
- A Python virtual environment, conda environment, or equivalent
- Node.js 20+ or 22+
- npm

## First-time setup

\`\`\`bash
./install.command
\`\`\`

The installer creates a local \`.venv\`, installs backend dependencies, builds frontend static files, and can install a \`pdfnuptool\` command into \`~/.local/bin\`.

## Run

Double-click:

\`\`\`text
PDF N-up Tool.app
\`\`\`

Or run from Terminal:

\`\`\`bash
./pdfnuptool
\`\`\`

If you installed the command and \`~/.local/bin\` is in PATH:

\`\`\`bash
pdfnuptool
\`\`\`

The app opens at \`http://127.0.0.1:8010\`.

This preview app must stay in the project folder next to \`pdfnuptool\`, \`backend/\`, and \`frontend/\`.

Uploaded PDFs and exported files stay on your machine.
EOF

chmod +x "$STAGING_DIR/pdfnuptool"
chmod +x "$STAGING_DIR/install.command"
chmod +x "$STAGING_DIR/scripts/install_macos.sh"

(
  cd "$DIST_DIR"
  zip -qr "$ZIP_PATH" "$PACKAGE_NAME"
)

echo "$ZIP_PATH"
