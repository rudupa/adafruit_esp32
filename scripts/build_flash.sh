#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOARD_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$BOARD_DIR")"

PROJECT_DIR="$BOARD_DIR/zephyr_app"

# Ensure west is available
if ! command -v west &> /dev/null; then
    echo "Error: 'west' command not found. Please install it with 'pip install west' and ensure it's in your PATH."
    exit 1
fi

# Build the Zephyr application
echo "Building Zephyr application..."
west build -p auto -b esp32s3_devkitm "$PROJECT_DIR"

# Flash the application
echo "Flashing Zephyr application..."
west flash
