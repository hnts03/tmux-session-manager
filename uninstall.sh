#!/usr/bin/env bash
# tsm uninstall script
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
TARGET="$INSTALL_DIR/tsm"

echo "Removing tsm from $TARGET ..."

if [[ ! -f "$TARGET" ]]; then
  echo "tsm not found at $TARGET. Nothing to do."
  exit 0
fi

if [[ ! -w "$TARGET" ]]; then
  sudo rm -f "$TARGET"
else
  rm -f "$TARGET"
fi

echo "tsm uninstalled."
