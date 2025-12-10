#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TOOLS_DIR="$REPO_ROOT/tools/openocd-linux"
OPENOCD_BIN="$TOOLS_DIR/src/openocd"

echo "Installing build dependencies (sudo required) ..."
sudo apt-get update
sudo apt-get install -y git build-essential automake libtool pkg-config libusb-1.0-0-dev libftdi1-dev python3

if [ ! -d "$TOOLS_DIR/.git" ]; then
    echo "Fetching OpenOCD submodule..."
    git -C "$REPO_ROOT" submodule update --init tools/openocd-linux
fi

echo "Syncing OpenOCD nested submodules (jimtcl, etc.) ..."
git -C "$TOOLS_DIR" submodule update --init --recursive

if [ -x "$OPENOCD_BIN" ]; then
    echo "OpenOCD already built at $OPENOCD_BIN"
    exit 0
fi

pushd "$TOOLS_DIR" >/dev/null
echo "Bootstrapping OpenOCD build..."
./bootstrap
echo "Configuring ..."
./configure --disable-werror --enable-internal-jimtcl --enable-internal-libjaylink
echo "Compiling ..."
make -j"$(nproc)"
popd >/dev/null

if [ -x "$OPENOCD_BIN" ]; then
    echo "OpenOCD built successfully at $OPENOCD_BIN"
else
    echo "OpenOCD build failed" >&2
    exit 1
fi
