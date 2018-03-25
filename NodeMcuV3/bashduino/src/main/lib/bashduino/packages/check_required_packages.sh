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
required_variables "SNAPSHOT_DIRS" "CONFIG_DIR"

local config_dir="${CONFIG_DIR}"
[[ -z "$1" ]] || config_dir="$1"

for snapshot_dir in "${SNAPSHOT_DIRS[@]}"; do
	#echo "DEBUG: checking dir: ${snapshot_dir}"
	local snapshot_dir_abs="${config_dir}/${snapshot_dir}"
	[[ -e "${snapshot_dir_abs}" ]] || {
		die "Required directory '${snapshot_dir_abs}' doesn't exists after installing board" "SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/MISSING_PACKAGE_DIR"
	}
done