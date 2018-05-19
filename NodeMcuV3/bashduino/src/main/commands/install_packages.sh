#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
    required_variables "SNAPSHOT_DIRS" "CONFIG_DIR" "ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR"
}

# Input variables
#   ARGS | map | arguments values
run() {
    import "bashduino/snapshots/check_required_snapshots" as "check_required_snapshots"
    import "bashduino/indexes/get_required_indexes" as "get_required_indexes"
    import "bashduino/dependencies/check_required_dependencies" as "check_required_dependencies"

    install_dependencies_if_required() {
        check_required_dependencies
        success || {
            log "Installing dependencies..."
            run_command "install_dependencies"
            success || {
                die "Installing dependencies failed!" "DEPENDENCIES/INSTALLATION_FAILED"
            }
        }
    }

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

    install_indexes() {
        get_required_indexes
        local required_indexes=( "${RETURN_VALUE[@]}" )

        for index in "${required_indexes[@]}"; do
            log "Copying package index '${index}' from snapshots..."

            local snapshot_dir_index="${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}/${index}"
            [[ -f "${snapshot_dir_index}" ]] || {
                die "Snapshot index '${index}' does not exists!" "INSTALL_PACKAGES/NO_SNAPSHOT_FILE"
            }
            cp "${snapshot_dir_index}" "${CONFIG_DIR}" || die
        done

    }

    install_dependencies_if_required
    create_snapshot_if_required

    mkdir -p "${CONFIG_DIR}"

    for snapshot_dir in "${SNAPSHOT_DIRS[@]}"; do
        local snapshot_dir_abs="${CONFIG_DIR}/${snapshot_dir}"
        [[ -d "${snapshot_dir_abs}" ]] || {
            log "Installing package '${snapshot_dir}' from snapshots..."
            install_package "${snapshot_dir}"
        }
    done

    install_indexes

    log "All packages installed"
}