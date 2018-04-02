#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   apply given preferences to file preferences.txt in arduino config directory
# Params:
#   $1  name of associative array that hold preferences to be set
# Exit policy:
#   die only in fatal error
required_variables "CONFIG_DIR"

require "$1"
local -n apply_preferences_prefs="$1"

local target_file="${CONFIG_DIR}/preferences.txt"
local name_pattern="[a-zA-Z][a-zA-Z0-9_]*"
local pref_line_pattern="^[[:space:]]*(${name_pattern})=(.+)$"

[[ -f "${target_file}" ]] || {
    die "Target preferences file doesn't exists or is not file! (${target_file})" "COMMON/FILE_NOT_FOUND"
}

declare -A existing_prefs

local tmp_output="$(mktemp)"
while read -r; do
    local line="${REPLY}"
    [[ "${line}" =~ $pref_line_pattern ]] || {
        printf "%s\n" "${line}" >> "${tmp_output}"
        continue
    }
    local pref_name="${BASH_REMATCH[1]}"
    local pref_value="${BASH_REMATCH[2]}"

    if [[ -v "apply_preferences_prefs[${pref_name}]" ]]; then
        existing_prefs["${pref_name}"]="true"
        printf "%s=%s\n" "${pref_name}" "${apply_preferences_prefs[${pref_name}]}" >> "${tmp_output}"
        continue
    fi
    printf "%s\n" "${line}" >> "${tmp_output}"
done < "${target_file}"

for pref_name in "${!apply_preferences_prefs[@]}"; do
    [[ -v existing_prefs["${pref_name}"] ]] || {
        printf "%s=%s\n" "${pref_name}" "${apply_preferences_prefs[${pref_name}]}" >> "${tmp_output}"
    }
done

mv "${tmp_output}" "${target_file}"

log "Arduino preferences updated... (${target_file})"