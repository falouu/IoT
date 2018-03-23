#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   checks, if required packages are installed in Arduino config directory
# Exit policy:
#   die, if checks fails
#

required_variables "SNAPSHOT_DIRS" "CONFIG_DIR"

for snapshot_dir in "${SNAPSHOT_DIRS[@]}"; do
	#echo "DEBUG: checking dir: ${snapshot_dir}"
	local snapshot_dir_abs="${CONFIG_DIR}/${snapshot_dir}"
	[[ -e "${snapshot_dir_abs}" ]] || {
		die "Required directory '${snapshot_dir_abs}' doesn't exists after installing board" "SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/MISSING_PACKAGE_DIR"
	}
done