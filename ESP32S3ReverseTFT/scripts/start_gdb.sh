#!/bin/bash
set -euo pipefail

usage() {
    cat >&2 <<'EOF'
Usage: start_gdb.sh [--elf <path>]

Runs xtensa-esp32s3-elf-gdb against the compiled ELF and feeds it the
preconfigured esp32s3.gdbinit script so it auto-connects to OpenOCD.

Options:
  --elf <path>   Explicit path to the ELF image (defaults to the first
                 *.elf file under ESP32S3ReverseTFT/esp-idf/build).
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOARD_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$BOARD_DIR")"
PROJECT_DIR="$BOARD_DIR/esp-idf"
GDB_INIT="$SCRIPT_DIR/esp32s3.gdbinit"
GDB_BIN="${XTENSA_GDB:-xtensa-esp32s3-elf-gdb}"

DEFAULT_IDF_PATH="$REPO_ROOT/third_party/esp-idf"
IDF_PATH="${IDF_PATH:-$DEFAULT_IDF_PATH}"
EXPORT_SCRIPT="$IDF_PATH/export.sh"

if [[ ! -f "$EXPORT_SCRIPT" ]]; then
    echo "ESP-IDF export script not found at: $EXPORT_SCRIPT" >&2
    echo "Set IDF_PATH to your ESP-IDF checkout before running this helper." >&2
    exit 1
fi

TMP_EXPORT="$(mktemp)"
trap 'rm -f "$TMP_EXPORT"' EXIT
tr -d '\r' < "$EXPORT_SCRIPT" > "$TMP_EXPORT"
source "$TMP_EXPORT"

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
    if [[ ! -d "$PROJECT_DIR/build" ]]; then
        echo "Build directory not found. Run idf.py build first." >&2
        exit 1
    fi
    mapfile -t ELF_CANDIDATES < <(find "$PROJECT_DIR/build" -maxdepth 1 -name '*.elf' -print 2>/dev/null)
    if [[ ${#ELF_CANDIDATES[@]} -eq 0 ]]; then
        echo "No ELF files found under $PROJECT_DIR/build. Build the project or pass --elf <path>." >&2
        exit 1
    fi
    ELF_PATH="${ELF_CANDIDATES[0]}"
fi

if [[ ! -f "$ELF_PATH" ]]; then
    echo "ELF file not found: $ELF_PATH" >&2
    exit 1
fi

if ! command -v "$GDB_BIN" >/dev/null 2>&1; then
    echo "GDB binary not found: $GDB_BIN" >&2
    echo "Ensure you've sourced ESP-IDF's export script so xtensa-esp32s3-elf-gdb is in PATH." >&2
    exit 1
fi

exec "$GDB_BIN" -x "$GDB_INIT" "$ELF_PATH"
