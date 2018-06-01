#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   checks, if required packages are installed in Arduino config directory
# Params:
#   $1  arduino settings directory to scan | string | default: $CONFIG_DIR
# Exit policy:
#   die, if checks fails
#
required_variables "CONFIG_DIR"
import "bashduino/indexes/check_required_indexes" as "check_required_indexes"
import "bashduino/snapshots/get_snapshot_dirs" as "get_snapshot_dirs"

local config_dir="${CONFIG_DIR}"
[[ -z "$1" ]] || config_dir="$1"

get_snapshot_dirs "${config_dir}"
success || {
    die "Cannot determine required snapshot dirs? Is index file successfully created in '${config_dir}' directory?"
}
local snapshot_dirs=( "${RETURN_VALUE[@]}" )

for snapshot_dir in "${snapshot_dirs[@]}"; do
	#echo "DEBUG: checking dir: ${snapshot_dir}"
	local snapshot_dir_abs="${config_dir}/${snapshot_dir}"
	[[ -e "${snapshot_dir_abs}" ]] || {
		die "Required directory '${snapshot_dir_abs}' doesn't exists after installing board" "SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/MISSING_PACKAGE_DIR"
	}
done

check_required_indexes "${config_dir}"
success || {
    die "Package index file does not exists after installing board!" "COMMON/FILE_NOT_FOUND"
}