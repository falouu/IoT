#/usr/bin/env bash
# DO NOT CALL THIS FILE!

errcho(){ >&2 echo "ERROR: $@"; }
die(){ errcho "$1"; exit "${ERROR_CODES[${2}]}"; }
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

declare -A ERROR_CODES

ERROR_CODES["RUN/NO_COMMAND"]=1