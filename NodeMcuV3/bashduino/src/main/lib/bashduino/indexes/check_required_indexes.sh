#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   checks, if required indexes are installed in given directory
# Params:
#   $1  directory to scan for index file | string
# Returns:
#   0   check success - index exists
#   1   check fails  - index does not exist
# Exit policy:
#   die only on unexpected error
#
import "bashduino/indexes/get_required_indexes" as "get_required_indexes"

require "$1"
local config_dir="$1"

get_required_indexes
local required_indexes=( "${RETURN_VALUE[@]}" )

for index in "${required_indexes[@]}"; do
    [[ -f "${config_dir}/${index}" ]] || {
        return 1
    }
done

return 0