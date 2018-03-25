#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

required_variables "PORT"


if [[ ! -e "${PORT}" ]]; then
	die "'${PORT}' file does not exists" "IDE/PORT_NOT_EXISTS"
fi

if [[ ! -c "${PORT}" ]]; then
	die "'${PORT}' file is not a device!" "IDE/PORT_NOT_DEVICE"
fi

PORT_FILE_OWNER_GROUP=$(stat --format %g "${PORT}")

PORT_FILE_OWNER_GROUP_NAME=$(getent group ${PORT_FILE_OWNER_GROUP} | cut -f1 -d':')

echo "'${PORT}' file is owned by group '${PORT_FILE_OWNER_GROUP_NAME}'"


if [[ ! -w "${PORT}" ]]; then
	id -G "$USER" | grep -qw "${PORT_FILE_OWNER_GROUP}"
	success || {
		log "Current user (${USER}) does not belong to group '${PORT_FILE_OWNER_GROUP_NAME}', so the user can't access the file"
		echo "Do you want to add user '${USER}' to group '${PORT_FILE_OWNER_GROUP_NAME}'?"
		yes_or_no || die "No is no" 4

		sudo usermod -a -G "${PORT_FILE_OWNER_GROUP_NAME}" "${USER}"
		success || {
			die "Cannot add user '${USER}' to group '${PORT_FILE_OWNER_GROUP_NAME}'" 5
		}

		log "You have to logout and login to get the group permissions!"
		exit 0
	}


	die "'${PORT}' file is not writable by current user!" 3
else
	log "Checking permissions... OK"
fi


update_config_dir_from_snapshot() {

}

update_config_dir_from_snapshot



# Dodaj definicję mikrokontrolera esp8266
# http://arduino.esp8266.com/stable/package_esp8266com_index.json
# * PReferences -> Additional Platforms URL
# * Narzędzia -> Płytka -> Menadżer płytek -> esp8266 -> install
# * Narzędzia -> Płytka -> NodeMCU 1.0 (ESP-12E Module)
# * Narzędzia -> Port -> $PORT

# preferencje Arduino IDE są zapisane tutaj: ~/.arduino15