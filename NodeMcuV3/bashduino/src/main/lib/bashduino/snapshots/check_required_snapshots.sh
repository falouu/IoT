#!/usr/bin/env bash

#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   checks, if required packages are snapshoted
# Returns:
#   0 check positive
#   1 check negative
# Exit policy:
#   exit only on unexpected error
#

required_variables "SNAPSHOT_DIRS" "ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR"

for snapshot_dir in "${SNAPSHOT_DIRS[@]}"; do
	local snapshot_file_abs="${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}/${snapshot_dir}/archive.tar.bz2"
	[[ -f "${snapshot_file_abs}" ]] || {
		return 1
	}
done

return 0