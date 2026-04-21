#!/usr/bin/env bash
# tsm install script
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="0.1.0"

need_sudo() { [[ ! -w "$INSTALL_DIR" ]]; }

echo "tsm $VERSION installer"
echo "Installing to $INSTALL_DIR ..."

if need_sudo; then
  sudo install -m 755 "$SCRIPT_DIR/bin/tsm" "$INSTALL_DIR/tsm"
else
  install -m 755 "$SCRIPT_DIR/bin/tsm" "$INSTALL_DIR/tsm"
fi

echo "tsm installed successfully."
echo "Run 'tsm' to get started, or 'tsm help' for usage."
