#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
  required_variables "BASHDUINO_SRC_ROOT_DIR" "ROOT_DIR" "CONFIG_DIR" "ARCH"
}

# Input variables
#   ARGS | map | arguments values
run() {
    import "bashduino/snapshots/get_hardware_dir" as "get_hardware_dir"

    format_dir() {
       local dirr="$1"
       if [[ "${dirr#${HOME}/}" != "${dirr}" ]]; then
         dirr="${dirr/${HOME}/\$ENV\{HOME\}}"
       fi
       printf "%s" "${dirr}"
    }

    get_hardware_dir
    local hardware_dir="${RETURN_VALUE}"

    local cmake_filename="CMakeLists.txt"
    local template_name="CMakeLists.template.txt"
    local default_template_abs="${BASHDUINO_SRC_ROOT_DIR}/resources/${template_name}"
    local custom_template_abs="${ROOT_DIR}/${template_name}"
    local cmake_abs="${ROOT_DIR}/${cmake_filename}"

    if [[ ! -f "${custom_template_abs}" ]]; then
        log "${template_name} file not found in root directory, creating one with default content..."
        cp "${default_template_abs}" "${custom_template_abs}"
        success || {
            die "Creating ${template_name} file FAILED" "GENERAL/CANNOT_CREATE_FILE"
        }
    fi

    local include_dirs=( "$(format_dir "${CONFIG_DIR}/${hardware_dir}cores/${ARCH}/")" )

    local libraries_parent_dir="${CONFIG_DIR}/${hardware_dir}libraries/"

    for lib_dir in "${libraries_parent_dir}"*; do
        [[ -d "${lib_dir}" ]] || {
           continue
        }
        include_dirs+=( "$(format_dir "${lib_dir}/src")" )
    done

    local include_dirs_block=""

    for include_dir in "${include_dirs[@]}"; do
        include_dirs_block+=$'\n'"include_directories(${include_dir})"
    done

    log "Creating '${cmake_filename}' file..."

    local template_content="$(< "${custom_template_abs}")"
    printf "%s" "${template_content/\%includes\%/${include_dirs_block}}" > "${cmake_abs}"
}