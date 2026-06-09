#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v0.2.0}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
PACKAGE_NAME="pdf-nup-tool-${VERSION}-macos-source"
STAGING_DIR="$DIST_DIR/$PACKAGE_NAME"
ZIP_PATH="$DIST_DIR/$PACKAGE_NAME.zip"

rm -rf "$STAGING_DIR" "$ZIP_PATH"
mkdir -p "$STAGING_DIR"

rsync -a "$ROOT_DIR/" "$STAGING_DIR/" \
  --exclude ".git/" \
  --exclude ".DS_Store" \
  --exclude "__pycache__/" \
  --exclude "*.pyc" \
  --exclude "dist/" \
  --exclude "frontend/node_modules/" \
  --exclude "frontend/dist/" \
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

This package is a macOS source preview package.

## Requirements

- Conda environment named \`bio\`
- Python 3.10+
- Node.js 20+ or 22+
- npm

## First-time setup

\`\`\`bash
conda activate bio
python -m pip install -r backend/requirements.txt
cd frontend
npm install
cd ..
\`\`\`

## Run

\`\`\`bash
./pdfnuptool
\`\`\`

The app opens at \`http://127.0.0.1:5173\`.

Uploaded PDFs and exported files stay on your machine.
EOF

chmod +x "$STAGING_DIR/pdfnuptool"

(
  cd "$DIST_DIR"
  zip -qr "$ZIP_PATH" "$PACKAGE_NAME"
)

echo "$ZIP_PATH"
