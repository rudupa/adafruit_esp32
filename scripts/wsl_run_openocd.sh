#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TOOLS_DIR="$REPO_ROOT/tools/openocd-linux"
OPENOCD_BIN="$TOOLS_DIR/src/openocd"
SCRIPT_PATH="$TOOLS_DIR/tcl"

if [ ! -x "$OPENOCD_BIN" ]; then
    echo "OpenOCD binary not found. Running setup..."
    bash "$SCRIPT_DIR/wsl_setup_openocd.sh"
fi

if [ ! -x "$OPENOCD_BIN" ]; then
    echo "OpenOCD binary still missing at $OPENOCD_BIN" >&2
    exit 1
fi

echo "Starting OpenOCD..."
# sudo is required for USB access in WSL unless udev rules are set up
sudo "$OPENOCD_BIN" -s "$SCRIPT_PATH" -f board/esp32s3-builtin.cfg "$@"
