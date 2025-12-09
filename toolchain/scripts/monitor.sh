#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROJECT_DIR="${REPO_ROOT}/SparkleMotionMini/esp-idf"
IDF_PATH="${REPO_ROOT}/third_party/esp-idf"
PORT="${PORT:-}"
BAUD="${BAUD:-115200}"

if [ ! -d "${PROJECT_DIR}" ]; then
    echo "error: ESP-IDF project not found at ${PROJECT_DIR}" >&2
    exit 1
fi

if [ ! -d "${IDF_PATH}" ]; then
    echo "error: ESP-IDF submodule missing. Run 'git submodule update --init --recursive third_party/esp-idf'." >&2
    exit 1
fi

# shellcheck disable=SC1091
source "${IDF_PATH}/export.sh" >/dev/null

monitor_cmd=(idf.py -C "${PROJECT_DIR}")
if [ -n "${PORT}" ]; then
    monitor_cmd+=(-p "${PORT}")
fi
if [ -n "${BAUD}" ]; then
    monitor_cmd+=(-b "${BAUD}")
fi
monitor_cmd+=(monitor)

"${monitor_cmd[@]}"
