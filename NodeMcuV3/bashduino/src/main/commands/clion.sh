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
    import "bashduino/sketches/get_sketches" as "get_sketches"
    import "bashduino/sketches/get_sketch_file" as "get_sketch_file"

    run_command "install_packages"
    success || {
        die "Installing packages FAILED"
    }

    replace_prefix() {
        require "$1"
        local text="$1"
        require "$2"
        local prefix="$2"
        local replacement="$3"

        if [[ "${text#${prefix}}" != "${text}" ]]; then
          text="${text/${prefix}/${replacement}}"
        fi
        printf "%s" "${text}"
    }

    format_dir() {
        require "$1"
        local dirr="$1"
        replace_prefix "${dirr}" "${HOME}/" "\$ENV{HOME}/"
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

        local src_lib_dir="${lib_dir}/src"
        if [[ -d "${src_lib_dir}" ]]; then
            include_dirs+=( "$(format_dir "${src_lib_dir}")" )
        else
            include_dirs+=( "$(format_dir "${lib_dir}")" )
        fi
    done

    local include_dirs_block=""

    for include_dir in "${include_dirs[@]}"; do
        include_dirs_block+=$'\n'"include_directories(${include_dir})"
    done

    log "Creating '${cmake_filename}' file..."

    local template_content="$(< "${custom_template_abs}")"

    template_content="${template_content/\%includes\%/${include_dirs_block}}"

    get_sketches
    local sketches=( "${RETURN_VALUE[@]}" )

    local sources_block="SET(SOURCE_FILES"$'\n'

    for sketch in "${sketches[@]}"; do
        get_sketch_file "${sketch}"
        local sketch_file="${RETURN_VALUE}"
        sources_block+="  $(replace_prefix "${sketch_file}" "${ROOT_DIR}/" "")"$'\n'
    done
    sources_block+=")"

    template_content="${template_content/\%source_files\%/${sources_block}}"

    printf "%s" "${template_content}" > "${cmake_abs}"


}