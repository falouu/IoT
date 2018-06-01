#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
    required_variables "ARDUINO_CMD" "PACKAGE" "ARCH" "VERSION" "ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR" "CONFIG_DIR" "BOARDSMANAGER_URL"

#  TODO: po co to było?
#    map.set PARAMS[configDir][name] "config-dir"
#    map.set PARAMS[configDir][description] "arduino config directory"
#    map.set PARAMS[configDir][defaultDescription] "default arduino config dir"
#    map.set PARAMS[configDir][required] "false"
#    map.set PARAMS[configDir][valuePlaceholder] "directory"
}

# Input variables
#   ARGS | map | arguments values
run() {
    import "bashduino/packages/check_required_packages" as "check_required_packages"
    import "bashduino/indexes/get_required_indexes" as "get_required_indexes"
    import "bashduino/snapshots/get_snapshot_dirs" as "get_snapshot_dirs"

    arduino_config_tmp_dir="$(mktemp -d)"
    debug "Downloading packages to temporary directory: '${arduino_config_tmp_dir}'..."

    die_clean() {
        rm -rf "${arduino_config_tmp_dir}"
        die "$1" "$2"
    }

    ${ARDUINO_CMD} --install-boards ${PACKAGE}:${ARCH}:${VERSION} \
      --pref boardsmanager.additional.urls="${BOARDSMANAGER_URL}" \
      --pref settings.path="${arduino_config_tmp_dir}"

    check_required_packages "${arduino_config_tmp_dir}" || die_clean

    assert_snapshot_dir() {
        [[ -d "${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}" ]] \
          || mkdir "${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}"
    }

    archive_package() {
        local package_dir target_dir
        require "$1"
        package_dir="$1"

        assert_snapshot_dir

        target_dir="${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}/${package_dir}"
        mkdir -p "${target_dir}" || die_clean

        pushd "${arduino_config_tmp_dir}"
        tar --create --bzip2 --sparse --file "${target_dir}/archive.tar.bz2" "${package_dir}"
        success || {
            rm "${target_dir}"/* 2>/dev/null
            die "archive creation failed. Source: '${package_dir}'. CWD: '$(pwd)'" \
                "SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/ARCHIVE_CREATE_FAILED"
        }
        popd
    }

    archive_indexes() {
        assert_snapshot_dir
        local target_dir="${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}"

        get_required_indexes
        local required_indexes=( "${RETURN_VALUE[@]}" )

        pushd "${arduino_config_tmp_dir}"
        for index in "${required_indexes[@]}"; do
            log "Creating snapshot of index '${index}'..."
            cp "${index}" "${target_dir}" || die_clean
        done
        popd
    }

    log "Creating snapshot of indexes..."
    archive_indexes

    get_snapshot_dirs "${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}"
    local snapshot_dirs=( "${RETURN_VALUE[@]}" )

    for snapshot_dir in "${snapshot_dirs[@]}"; do
        log "Creating snapshot of dir '${snapshot_dir}'..."
        archive_package "${snapshot_dir}"
    done



    rm -rf "${arduino_config_tmp_dir}"

    log "All snapshots created in directory '${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}'"

    #255

    #--install-boards package name:platform architecture[:version]

    # --install-boards esp8266:esp8266:2.4.1


    # boardsmanager.additional.urls=http://arduino.esp8266.com/stable/package_esp8266com_index.json


    # --pref name=value

    # --pref boardsmanager.additional.urls=http://arduino.esp8266.com/stable/package_esp8266com_index.json
}