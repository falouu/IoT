#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   checks if device is connected to the port and configure the port
# Returns:
#   0
# RETURN_VALUE:
#   sketch file path
# Exit policy:
#   exit with error if configuring port failed or device is not connected

required_variables "PORT"

if [[ ! -e "${PORT}" ]]; then
    die "'${PORT}' file does not exists" "IDE/PORT_NOT_EXISTS"
fi

if [[ ! -c "${PORT}" ]]; then
    die "'${PORT}' file is not a device!" "IDE/PORT_NOT_DEVICE"
fi

local PORT_FILE_OWNER_GROUP=$(stat --format %g "${PORT}")

local PORT_FILE_OWNER_GROUP_NAME=$(getent group ${PORT_FILE_OWNER_GROUP} | cut -f1 -d':')

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