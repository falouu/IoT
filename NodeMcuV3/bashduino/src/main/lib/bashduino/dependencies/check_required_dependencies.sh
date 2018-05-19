#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   checks, if required dependencies are installed in artifacts directory
# Returns:
#   0   check success - all dependencies installed
#   1   check fails  - one ore more dependency not installed
# Exit policy:
#   die only on unexpected error
#

import "bashduino/dependencies/is_dependency_installed" as "is_dependency_installed"

get_dependencies

map.get_keys_or_empty DEPENDENCIES
local dep_ids=( "${RETURN_VALUE[@]}" )
local result=0

for dep_id in "${dep_ids[@]}"; do
    map.get_value_or_die DEPENDENCIES["${dep_id}"][file]
    local dep_file="${RETURN_VALUE}"
    is_dependency_installed "${dep_id}" "${dep_file}"
    success || {
        result=1
        break
    }
done

map.unset DEPENDENCIES
return ${result}
