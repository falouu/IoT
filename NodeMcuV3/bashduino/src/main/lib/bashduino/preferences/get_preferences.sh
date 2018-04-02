#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   returns prefernces to set in associative array
# Params:
#   $1  name of associative array to be filled by preferences
# Exit policy:
#   die only in fatal error

require "$1"
local -n output="$1"

local pref_file="${ROOT_DIR}/config/preferences.txt"
local name_pattern="[a-zA-Z][a-zA-Z0-9_]*"
local pref_line_pattern="^[[:space:]]*(${name_pattern})=(.+)$"


[[ -f "${pref_file}" ]] || {
    return
}

while read -r line; do
    [[ "${line}" =~ $pref_line_pattern ]] || {
        continue
    }
    local pref_name="${BASH_REMATCH[1]}"
    local pref_value="${BASH_REMATCH[2]}"

    #debug "pref_name='${pref_name}'; pref_value='${pref_value}'"

    output[${pref_name}]="${pref_value}"

done < "${pref_file}"


