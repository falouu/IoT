#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   checks, if given dependency is installed in artifacts directory
# Params:
#   $1  dependency id
#   $2  dependency filename
# Returns:
#   0   check success - dependency is installed
#   1   check fails  - dependency is not installed
# Exit policy:
#   die only on unexpected error
#

required_variables "DEPENDENCIES_DIR"

require "$1"
local dep_id="$1"
require "$2"
local dep_file="$2"

local dep_file_abs="${DEPENDENCIES_DIR}/${dep_id}/${dep_file}"
if [[ -f "${dep_file_abs}" ]]; then
    return 0
else
    return 1
fi
