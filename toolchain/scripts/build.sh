#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROJECT_DIR="${REPO_ROOT}/SparkleMotionMini/esp-idf"
IDF_PATH="${REPO_ROOT}/third_party/esp-idf"
IDF_TARGET="${IDF_TARGET:-esp32}"

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

idf.py -C "${PROJECT_DIR}" set-target "${IDF_TARGET}"
idf.py -C "${PROJECT_DIR}" build
