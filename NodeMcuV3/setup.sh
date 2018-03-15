#/usr/bin/env bash

# ------CONFIG--------
PORT=/dev/ttyUSB0

# ------UTILS---------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


errcho(){ >&2 echo "ERROR: $@"; }
die(){ errcho "$1"; exit "$2"; }
success(){ return "$?"; }
function yes_or_no {
    while true; do
        read -p "Your answer [y/n]: " yn
        case $yn in
            [Yy]) return 0 ;;
            [Nn]) return 1 ;;
			*) echo "Invalid answer" ;;
        esac
    done
}


# ------PROGRAM-------
if [[ ! -e "${PORT}" ]]; then
	die "'${PORT}' file does not exists" 1
fi

if [[ ! -c "${PORT}" ]]; then
	die "'${PORT}' file is not a device!" 2
fi



PORT_FILE_OWNER_GROUP=$(stat --format %g "${PORT}")

PORT_FILE_OWNER_GROUP_NAME=$(getent group ${PORT_FILE_OWNER_GROUP} | cut -f1 -d':')

echo "'${PORT}' file is owned by group '${PORT_FILE_OWNER_GROUP_NAME}'"

if [[ ! -w "${PORT}" ]]; then
	id -G "$USER" | grep -qw "${PORT_FILE_OWNER_GROUP}"
	success || {
		echo "Current user (${USER}) does not belong to group '${PORT_FILE_OWNER_GROUP_NAME}', so the user can't access the file"
		echo "Do you want to add user '${USER}' to group '${PORT_FILE_OWNER_GROUP_NAME}'?"
		yes_or_no || die "No is no" 4

		sudo usermod -a -G "${PORT_FILE_OWNER_GROUP_NAME}" "${USER}"
		success || {
			die "Cannot add user '${USER}' to group '${PORT_FILE_OWNER_GROUP_NAME}'" 5
		}

		echo "You have to logout and login to get the group permissions!"
		exit 0
	}


	die "'${PORT}' file is not writable by current user!" 3
fi

#sudo usermod -a -G dialout <username>