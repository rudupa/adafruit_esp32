#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOARD_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$BOARD_DIR")"

PROJECT_DIR="$BOARD_DIR/esp-idf"

PROJECT_DIR="$PROJECT_DIR" "${REPO_ROOT}/scripts/wsl_build_flash.sh" "$@"
