#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
   required_variables "ARTIFACTS_DIR"
}

# Input variables
#   ARGS | map | arguments values
run() {
    import "bashduino/dependencies/is_dependency_installed" as "is_dependency_installed"

    install_dependency() {
        require "$1"
        local dep_id="$1"
        require "$2"
        local dep_file="$2"
        require "$3"
        local dep_url="$3"

        local dep_file_dir="${ARTIFACTS_DIR}/bashduino-dependencies/${dep_id}"
        local dep_file_abs="${dep_file_dir}/${dep_file}"

        mkdir -p "${dep_file_dir}" || die "Cannot create directory '${dep_file_dir}'" "GENERAL/CANNOT_CREATE_DIRECTORY"
        log "Downloading dependency '${dep_id}' from '${dep_url}'..."
        curl "${dep_url}" > "${dep_file_abs}"
        success || {
            errcho "Cannot download dependency: '${dep_url}'"
            die "dependency '${dep_id}' installation failed" "DEPENDENCIES/INSTALLATION_FAILED"
        }
    }

    get_dependencies
    map.get_keys_or_empty DEPENDENCIES
    local dep_ids=( "${RETURN_VALUE[@]}" )

    for dep_id in "${dep_ids[@]}"; do
        map.get_value_or_die DEPENDENCIES["${dep_id}"][file]
        local dep_file="${RETURN_VALUE}"
        is_dependency_installed "${dep_id}" "${dep_file}"
        success || {
            map.get_value_or_die DEPENDENCIES["${dep_id}"][url]
            local dep_url="${RETURN_VALUE}"
            install_dependency "${dep_id}" "${dep_file}" "${dep_url}"
        }
    done


}