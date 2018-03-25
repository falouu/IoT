#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

required_variables "SNAPSHOT_DIRS" "CONFIG_DIR" "ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR"

install_package() {
    require "$1"
    local package_dir="$1"
    local snapshot_dir_archive="${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}/${package_dir}/archive.tar.bz2"
    local config_package_dir_abs="${CONFIG_DIR}/${snapshot_dir}"

    [[ -f "${snapshot_dir_archive}" ]] || {
        die "Snapshot file for package '${package_dir}' does not exists!" "INSTALL_PACKAGES/NO_SNAPSHOT_FILE"
    }

    tar --extract --directory "${CONFIG_DIR}" --file "${snapshot_dir_archive}"
    success || die "unpacking failed" "INSTALL_PACKAGES/UNPACK_FAILED"
}

for snapshot_dir in "${SNAPSHOT_DIRS[@]}"; do
    snapshot_dir_abs="${CONFIG_DIR}/${snapshot_dir}"
    [[ -e "${snapshot_dir_abs}" ]] || {
        log "Installing package '${snapshot_dir}' from snapshots..."
        install_package "${snapshot_dir}"
    }
done

log "All packages installed"