#!/bin/bash
set -euo pipefail

usage() {
    cat >&2 <<'EOF'
Usage: start_gdb.sh [--elf <path>] [--gdb <binary>]

Runs xtensa-esp32s3 GDB against the Zephyr ELF and feeds it the
preconfigured esp32s3.gdbinit script so it auto-connects to OpenOCD.

Options:
  --elf <path>   Explicit path to the ELF image (default: zephyr_app/build/zephyr/zephyr.elf)
  --gdb <binary> Override the GDB binary (default: xtensa-espressif_esp32s3_zephyr-elf-gdb)
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DEFAULT_ELF="$REPO_ROOT/zephyr_app/build/zephyr/zephyr.elf"
GDB_INIT="$SCRIPT_DIR/esp32s3.gdbinit"
GDB_BIN="${GDB_BIN:-xtensa-espressif_esp32s3_zephyr-elf-gdb}"
ELF_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --elf)
            if [[ $# -lt 2 ]]; then
                echo "--elf requires a value" >&2
                usage
                exit 1
            fi
            ELF_PATH="$2"
            shift 2
            ;;
        --gdb)
            if [[ $# -lt 2 ]]; then
                echo "--gdb requires a value" >&2
                usage
                exit 1
            fi
            GDB_BIN="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ -z "$ELF_PATH" ]]; then
    ELF_PATH="$DEFAULT_ELF"
fi

if [[ ! -f "$ELF_PATH" ]]; then
    echo "ELF file not found: $ELF_PATH" >&2
    echo "Build with: west build -p auto -b esp32s3_devkitm zephyr_app" >&2
    exit 1
fi

if ! command -v "$GDB_BIN" >/dev/null 2>&1; then
    echo "GDB binary not found: $GDB_BIN" >&2
    echo "Ensure the Zephyr SDK (xtensa-espressif_esp32s3) is on PATH." >&2
    exit 1
fi

exec "$GDB_BIN" -x "$GDB_INIT" "$ELF_PATH"
