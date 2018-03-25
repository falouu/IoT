#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

required_variables "SNAPSHOT_DIRS" "CONFIG_DIR" "ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR"

import "bashduino/snapshots/check_required_snapshots" as "check_required_snapshots"

create_snapshot_if_required() {
    check_required_snapshots
    success || {
        log "Creating snapshots..."
        run_command "snapshot"
        success || {
            die "Creating snapshots failed!" "IDE/CREATE_SNAPSHOTS_FAILED"
        }
    }

}

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


create_snapshot_if_required

for snapshot_dir in "${SNAPSHOT_DIRS[@]}"; do
    snapshot_dir_abs="${CONFIG_DIR}/${snapshot_dir}"
    [[ -e "${snapshot_dir_abs}" ]] || {
        log "Installing package '${snapshot_dir}' from snapshots..."
        install_package "${snapshot_dir}"
    }
done

log "All packages installed"