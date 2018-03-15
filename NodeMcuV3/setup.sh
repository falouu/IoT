#/usr/bin/env bash

# ------CONFIG--------
PORT=/dev/ttyUSB0

# ------UTILS---------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


errcho(){ >&2 echo "ERROR: $@"; }
die(){ errcho "$1"; exit "$2"; }


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


#sudo usermod -a -G dialout <username>