#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   get snapshot dirs from boards manager json
# Params:
#   $1  | custom config dir [optional] [default: arduino config dir (CONFIG_DIR)
# Returns:
#   0  | if no error
# RETURN_VALUE
#   an array of snapshot dirs
# Exit policy:
#   - exit when platform definition not found in index file
#   - exit on unexpected error

required_variables "CONFIG_DIR" "PACKAGE" "ARCH" "VERSION"

import "bashduino/indexes/get_required_indexes" as "get_required_indexes"
import "bashduino/cache/get_cache_file" as "get_cache_file"
import "bashduino/snapshots/get_hardware_dir" as "get_hardware_dir"

local config_dir="${CONFIG_DIR}"
if [[ "$1" ]]; then
    config_dir="$1"
fi

get_cache_file "bashduino/snapshots/get_snapshots_dirs" "snapshots_dirs"
local cache_file="${RETURN_VALUE}"
local cache_exists="false"

if [[ -f "${cache_file}" ]]; then
    source "$cache_file"
    [[ "$(declare -p SNAPSHOT_DIRS)" =~ "declare -a" ]] && {
        cache_exists="true"
    }
fi


if [[ "${cache_exists}" != "true" ]]; then
    get_required_indexes
    local required_index="${RETURN_VALUE[0]}"
    [[ "${required_index}" ]] || die "Index not found! Did you define BOARDSMANAGER_URL variable?"

    local required_index_abs="${config_dir}/${required_index}"

    get_search_index_pattern() {
        require "$1"
        local field="$1"
        require "$2"
        local value="$2"
        RETURN_VALUE="^[[:space:]]*\[\"packages\",([0-9]+),\"platforms\",([0-9]+),\"${field}\"\][[:space:]]+\"${value}\"$"
    }

    get_tools_dependencies_pattern() {
        require "$1"
        local package_index="$1"
        require "$2"
        local platform_index="$2"
        require "$3"
        local field="$3"
        local ret="^[[:space:]]*\[\"packages\",${package_index},\"platforms\",${platform_index},\"toolsDependencies\""
              ret+=",([0-9]+)\,\"${field}\"][[:space:]]+\"(.+)\"$"

        RETURN_VALUE="${ret}"
    }

    get_search_index_pattern ".+" ".+"
    local line_pattern="${RETURN_VALUE}"
    get_search_index_pattern "name" "${PACKAGE}"
    local name_line_pattern="${RETURN_VALUE}"
    get_search_index_pattern "architecture" "${ARCH}"
    local arch_line_pattern="${RETURN_VALUE}"
    get_search_index_pattern "version" "${VERSION}"
    local version_line_pattern="${RETURN_VALUE}"

    local current_package=0
    local current_platform=0
    local name_matched="false"
    local arch_matched="false"
    local version_matched="false"
    local found="false"

    local json_command="bash %depfile% -l < '${required_index_abs}'"

    local json_output
    json_output="$(call_dependency 'json' "${json_command}")"
    success || {
        die "calling json dependency failed"
    }

    while read -r; do
        local line="${REPLY}"

        [[ "${line}" =~ $line_pattern ]] || {
            continue
        }

        local package_index="${BASH_REMATCH[1]}"
        local platform_index="${BASH_REMATCH[2]}"

        if [[ "${package_index}" != "${current_package}" ]] || [[ "${platform_index}" != "${current_platform}" ]]; then
            name_matched="false"
            arch_matched="false"
            version_matched="false"
        fi

        current_package="${package_index}"
        current_platform="${platform_index}"

        if [[ "${line}" =~ $version_line_pattern ]]; then
            version_matched="true"
        elif [[ "${line}" =~ $name_line_pattern ]]; then
            name_matched="true"
        elif [[ "${line}" =~ $arch_line_pattern ]]; then
            arch_matched="true"
        fi

        if [[ "${version_matched}" == "true" ]] \
           && [[ "${name_matched}" == "true" ]] \
           && [[ "${arch_matched}" == "true" ]]; then

           found="true"
           break
        fi
    done <<< "${json_output}"

    success || {
        die "Searching for platform information in index file failed!"
    }

    [[ "${found}" == "true" ]] || {
       local msg="Definition for platform '{package: ${PACKAGE}, arch: ${ARCH}, version: ${VERSION}}' not found "
       msg+="in boardsmanager index file"
       die "${msg}" "GET_SNAPSHOT_DIRS/PLATFORM_DEFINITION_NOT_FOUND"
    }

    get_tools_dependencies_pattern "${current_package}" "${current_platform}" ".+"
    local tool_line_pattern="${RETURN_VALUE}"
    get_tools_dependencies_pattern "${current_package}" "${current_platform}" "name"
    local tool_name_pattern="${RETURN_VALUE}"
    get_tools_dependencies_pattern "${current_package}" "${current_platform}" "version"
    local version_name_pattern="${RETURN_VALUE}"

    local tools_names=()
    local tools_versions=()

    while read -r; do
        local line="${REPLY}"

        [[ "${line}" =~ $tool_line_pattern ]] || {
            continue
        }

        local tool_index="${BASH_REMATCH[1]}"

        if [[ "${line}" =~ $tool_name_pattern ]]; then
            local name="${BASH_REMATCH[2]}"
            tools_names[${tool_index}]="${name}"

        elif [[ "${line}" =~ $version_name_pattern ]]; then
            local version="${BASH_REMATCH[2]}"
            tools_versions[${tool_index}]="${version}"
        fi
    done <<< "${json_output}"

    get_hardware_dir
    local hardware_dir="${RETURN_VALUE}"

    local SNAPSHOT_DIRS=( "${hardware_dir}" )
    for tool_index in "${!tools_names[@]}"; do
        SNAPSHOT_DIRS+=( "packages/${PACKAGE}/tools/${tools_names[${tool_index}]}/${tools_versions[${tool_index}]}/" )
    done

    local declare_snapshots_line="$(declare -p SNAPSHOT_DIRS)"
    local declare_snapshots_line_pattern="^declare -a SNAPSHOT_DIRS='(.+)'$"

    if [[ "${declare_snapshots_line}" =~ $declare_snapshots_line_pattern ]]; then
        local definition="${BASH_REMATCH[1]}"
        printf '%s=%s' "SNAPSHOT_DIRS" "${definition}" > "${cache_file}"
    else
        die "Unexpected error when saving SNAPSHOT_DIRS cache"
    fi

fi

RETURN_VALUE=( "${SNAPSHOT_DIRS[@]}" )