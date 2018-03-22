#/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

required_variables "ARDUINO_CMD" "PACKAGE" "ARCH" "VERSION" "ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR" "SNAPSHOT_DIRS" "CONFIG_DIR"



${ARDUINO_CMD} --install-boards ${PACKAGE}:${ARCH}:${VERSION} --pref boardsmanager.additional.urls=http://arduino.esp8266.com/stable/package_esp8266com_index.json


for snapshot_dir in "${SNAPSHOT_DIRS[@]}"; do
	#echo "DEBUG: checking dir: ${snapshot_dir}"
	snapshot_dir_abs="${CONFIG_DIR}/${snapshot_dir}"
	[[ -e "${snapshot_dir_abs}" ]] || {
		die "Required directory '${snapshot_dir_abs}' doesn't exists after installing board" "SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/MISSING_PACKAGE_DIR"
	}
done

archive_package() {
	local package_dir target_dir
	require "$1"
	package_dir="$1"

	[[ -d "${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}" ]] \
	  || die "Arduino packages snapshot dir (${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}) doesn't exists!" \
	         "SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/MISSING_SNAPSHOTS_DIR"

	target_dir="${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}/${package_dir}"
	mkdir -p "${target_dir}" || die

	pushd "${CONFIG_DIR}"
	tar --create --bzip2 --sparse --file "${target_dir}/archive.tar.bz2" "${package_dir}"
	popd
	success || die "archive creation failed" "SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/ARCHIVE_CREATE_FAILED"
}

for snapshot_dir in "${SNAPSHOT_DIRS[@]}"; do
	log "Creating snapshot of dir '${snapshot_dir}'..."
	archive_package "${snapshot_dir}"
done

log "All snapshots created in directory '${ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR}'"

#255

#--install-boards package name:platform architecture[:version]

# --install-boards esp8266:esp8266:2.4.1


# boardsmanager.additional.urls=http://arduino.esp8266.com/stable/package_esp8266com_index.json


# --pref name=value

# --pref boardsmanager.additional.urls=http://arduino.esp8266.com/stable/package_esp8266com_index.json