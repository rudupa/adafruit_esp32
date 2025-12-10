#!/bin/bash
set -euo pipefail

FULLCLEAN="0"
USER_PROJECT_DIR="${PROJECT_DIR:-}"
usage() {
    cat >&2 <<'EOF'
Usage: wsl_build_flash.sh [--fullclean] [--project-dir <path>]

Options:
  --fullclean              Run 'idf.py fullclean' before building.
  --project-dir <path>     Override the ESP-IDF project directory. Defaults to
                           SparkleMotionMini/esp-idf unless PROJECT_DIR env is set.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fullclean)
            FULLCLEAN="1"
            shift
            ;;
        --project-dir)
            if [[ $# -lt 2 ]]; then
                echo "--project-dir requires a value" >&2
                usage
                exit 1
            fi
            USER_PROJECT_DIR="$2"
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

DEFAULT_IDF_PATH="$REPO_ROOT/third_party/esp-idf"
IDF_PATH="${IDF_PATH:-$DEFAULT_IDF_PATH}"
EXPORT_SCRIPT="$IDF_PATH/export.sh"

if [[ ! -f "$EXPORT_SCRIPT" ]]; then
    echo "ESP-IDF export script not found at: $EXPORT_SCRIPT" >&2
    echo "Set IDF_PATH to your ESP-IDF checkout before running this helper." >&2
    exit 1
fi

# Ensure CRLF line endings do not break the export script when repo is cloned via Windows.
TMP_EXPORT="$(mktemp)"
trap 'rm -f "$TMP_EXPORT"' EXIT
tr -d '\r' < "$EXPORT_SCRIPT" > "$TMP_EXPORT"
source "$TMP_EXPORT"

if ! command -v idf.py >/dev/null 2>&1; then
    echo "idf.py still not available after sourcing ESP-IDF environment." >&2
    exit 1
fi

PROJECT_DIR="${USER_PROJECT_DIR:-$REPO_ROOT/SparkleMotionMini/esp-idf}"
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "Project directory not found: $PROJECT_DIR" >&2
    exit 1
fi

pushd "$PROJECT_DIR" >/dev/null

echo "Building project in $PROJECT_DIR..."
if [[ "$FULLCLEAN" == "1" ]]; then
    BUILD_DIR="$PROJECT_DIR/build"
    if [[ -d "$BUILD_DIR" && ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
        echo "Removing non-CMake build directory at $BUILD_DIR before fullclean..."
        rm -rf "$BUILD_DIR"
    fi
    echo "Running idf.py fullclean before build..."
    idf.py fullclean
fi
idf.py build

echo "Flashing project + starting monitor..."
idf.py flash monitor

popd >/dev/null
