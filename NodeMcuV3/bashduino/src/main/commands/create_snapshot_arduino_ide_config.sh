#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
    required_variables "ARDUINO_CMD" "PACKAGE" "ARCH" "VERSION" "ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR" "SNAPSHOT_DIRS" "CONFIG_DIR" "BOARDSMANAGER_URL"

    map.set PARAMS[configDir][name] "config-dir"
    map.set PARAMS[configDir][description] "arduino config directory"
    map.set PARAMS[configDir][defaultDescription] "default arduino config dir"
    map.set PARAMS[configDir][required] "false"
    map.set PARAMS[configDir][valuePlaceholder] "directory"
}

# Input variables
#   ARGS | map | arguments values
run() {
    import "bashduino/packages/check_required_packages" as "check_required_packages"

    arduino_config_tmp_dir="$(mktemp -d)"

    die_clean() {
        rm -rf "${arduino_config_tmp_dir}"
        die "$1" "$2"
    }

    ${ARDUINO_CMD} --install-boards ${PACKAGE}:${ARCH}:${VERSION} \
      --pref boardsmanager.additional.urls="${BOARDSMANAGER_URL}" \
      --pref settings.path="${arduino_config_tmp_dir}"

    check_required_packages "${arduino_config_tmp_dir}" || die_clean

    archive_package() {
        local package_dir target_dir
        require "$1"
        package_dir="$1"

        [[ -d "${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}" ]] \
          || die "Arduino packages snapshot dir (${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}) doesn't exists!" \
                 "SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/MISSING_SNAPSHOTS_DIR"

        target_dir="${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}/${package_dir}"
        mkdir -p "${target_dir}" || die_clean

        pushd "${CONFIG_DIR}"
        tar --create --bzip2 --sparse --file "${target_dir}/archive.tar.bz2" "${package_dir}"
        success || die "archive creation failed" "SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/ARCHIVE_CREATE_FAILED"
        popd
    }

    for snapshot_dir in "${SNAPSHOT_DIRS[@]}"; do
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