#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
  required_variables "BASHDUINO_SRC_ROOT_DIR" "ROOT_DIR"
}

# Input variables
#   ARGS | map | arguments values
run() {
    import "bashduino/snapshots/get_hardware_dir" as "get_hardware_dir"


    get_hardware_dir
    local hardware_dir="${RETURN_VALUE}"

    local template_name="CMakeLists.template.txt"

    local default_template_abs="${BASHDUINO_SRC_ROOT_DIR}/resources/${template_name}"
    local custom_template_abs="${ROOT_DIR}/${template_name}"

    if [[ ! -f "${custom_template_abs}" ]]; then
        log "${template_name} file not found in root directory, creating one with default content..."
        cp "${default_template_abs}" "${custom_template_abs}"
        success || {
            die "Creating ${template_name} file FAILED" "GENERAL/CANNOT_CREATE_FILE"
        }
    fi

    local include_directories_block=""

    

    "include_directories("
}