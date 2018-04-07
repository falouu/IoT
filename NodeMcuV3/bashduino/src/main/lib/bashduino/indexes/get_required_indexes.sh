#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   get an array of required indexes
# RETURN_VALUE
#   an array of required indexes file names
# Exit policy:
#   die only on unexpected error


if [[ "${BOARDSMANAGER_URL}" ]]; then
    local package_index_filename="${BOARDSMANAGER_URL##*/}"
    [[ "${package_index_filename}" ]] || die "BOARDSMANAGER_URL has invalid value" "COMMON/VAR_INVALID_FORMAT"

    RETURN_VALUE=( "${package_index_filename}" )
else
    RETURN_VALUE=()
fi

