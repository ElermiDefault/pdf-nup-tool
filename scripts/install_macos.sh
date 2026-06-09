#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="$ROOT_DIR/.venv"
VENV_PYTHON="$VENV_DIR/bin/python"
FRONTEND_DIR="$ROOT_DIR/frontend"
COMMAND_DIR="${PDFNUPTOOL_COMMAND_DIR:-$HOME/.local/bin}"
COMMAND_PATH="$COMMAND_DIR/pdfnuptool"
INSTALL_COMMAND="${PDFNUPTOOL_INSTALL_COMMAND:-ask}"

die() {
  echo "Error: $*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local answer

  if [[ ! -t 0 ]]; then
    [[ "$default" == "y" ]]
    return
  fi

  read -r -p "$prompt" answer
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy]$ ]]
}

echo "PDF N-up Tool installer"
echo "Project: $ROOT_DIR"
echo

need_command python3
need_command node
need_command npm

python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else "Python 3.10+ is required")'

if [[ ! -d "$VENV_DIR" ]]; then
  echo "Creating Python virtual environment..."
  python3 -m venv "$VENV_DIR"
else
  echo "Using existing virtual environment: $VENV_DIR"
fi

echo "Installing backend dependencies..."
"$VENV_PYTHON" -m pip install --upgrade pip
"$VENV_PYTHON" -m pip install -r "$ROOT_DIR/backend/requirements.txt"

echo "Installing frontend dependencies..."
(
  cd "$FRONTEND_DIR"
  npm install
  npm run build
)

chmod +x "$ROOT_DIR/pdfnuptool"

should_install_command=false
case "$INSTALL_COMMAND" in
  1|true|yes|y) should_install_command=true ;;
  0|false|no|n) should_install_command=false ;;
  ask) prompt_yes_no "Install a pdfnuptool command to $COMMAND_PATH? [Y/n] " "y" && should_install_command=true ;;
  *) die "Invalid PDFNUPTOOL_INSTALL_COMMAND value: $INSTALL_COMMAND" ;;
esac

if [[ "$should_install_command" == "true" ]]; then
  mkdir -p "$COMMAND_DIR"
  cat > "$COMMAND_PATH" <<EOF
#!/usr/bin/env bash
exec "$VENV_PYTHON" "$ROOT_DIR/pdfnuptool" "\$@"
EOF
  chmod +x "$COMMAND_PATH"
  echo "Installed command: $COMMAND_PATH"
  case ":$PATH:" in
    *":$COMMAND_DIR:"*) ;;
    *)
      echo
      echo "Note: $COMMAND_DIR is not in PATH."
      echo "Add this line to your shell profile if the pdfnuptool command is not found:"
      echo "export PATH=\"$COMMAND_DIR:\$PATH\""
      ;;
  esac
else
  echo "Skipped command installation."
fi

echo
echo "Installation complete."
echo "Run from this project folder:"
echo "  ./pdfnuptool"
echo
echo "If you installed the command and it is in PATH, run:"
echo "  pdfnuptool"
