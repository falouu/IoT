#!/usr/bin/env bash

if [[ "${ARTIFACTS_DIR}" ]]; then
    ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR="${ARTIFACTS_DIR}/arduino-ide-packages"
    DEPENDENCIES_DIR="${ARTIFACTS_DIR}/bashduino-dependencies"
    CACHE_DIR="${ARTIFACTS_DIR}/cache"
fi

BASHDUINO_EVAL_FILE=""
BASHDUINO_EVAL_FILE_OLD=""
BASHDUINO_EVAL_LINE_OFFSET=""

