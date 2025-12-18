#!/bin/bash
set -euo pipefail

usage() {
    cat >&2 <<'EOF'
Usage: openocd_esp32s3.sh [--adapter-khz <khz>] [--help] [-- <extra OpenOCD args>]

Starts OpenOCD for the ESP32-S3 builtin USB JTAG using the esp32s3-builtin.cfg
from the checked-in OpenOCD submodule.

Options:
  --adapter-khz <khz>   Override adapter speed (default: 5000).
  --help                Show this help text.

Any arguments after `--` are passed straight through to OpenOCD.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
OPENOCD_ROOT="$REPO_ROOT/tools/openocd-linux"
OPENOCD_BIN="${OPENOCD_BIN:-$OPENOCD_ROOT/src/openocd}"
OPENOCD_TCL="${OPENOCD_TCL:-$OPENOCD_ROOT/tcl}"
BOARD_CFG="${BOARD_CFG:-$OPENOCD_TCL/board/esp32s3-builtin.cfg}"
ADAPTER_KHZ="5000"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --adapter-khz)
            if [[ $# -lt 2 ]]; then
                echo "--adapter-khz requires a value" >&2
                usage
                exit 1
            fi
            ADAPTER_KHZ="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --)
            shift
            EXTRA_ARGS+=("$@")
            break
            ;;
        *)
            EXTRA_ARGS+=("$1")
            shift
            ;;
    esac
done

if [[ ! -x "$OPENOCD_BIN" ]]; then
    echo "OpenOCD binary not found at $OPENOCD_BIN; configuring and building..." >&2
    cd "$OPENOCD_ROOT"
    ./bootstrap
    ./configure --enable-esp32 --enable-internal-jimtcl
    make -j
fi

if [[ ! -f "$BOARD_CFG" ]]; then
    echo "Board cfg not found: $BOARD_CFG" >&2
    exit 1
fi

echo "Starting OpenOCD (adapter_khz=${ADAPTER_KHZ})..."
exec "$OPENOCD_BIN" -s "$OPENOCD_TCL" -f "$BOARD_CFG" -c "adapter_khz $ADAPTER_KHZ" "${EXTRA_ARGS[@]}"
