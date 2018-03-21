#/usr/bin/env bash
# DO NOT CALL THIS FILE!

errcho(){ >&2 echo "ERROR: $@"; }
die(){ errcho "$1"; exit "${ERROR_CODES[${2}]}"; }
success(){ return "$?"; }
yes_or_no() {
    while true; do
        read -p "Your answer [y/n]: " yn
        case $yn in
            [Yy]) return 0 ;;
            [Nn]) return 1 ;;
			*) echo "Invalid answer" ;;
        esac
    done
}

# usage: containsElement "a string" "${array[@]}"
containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}
function join_by { local IFS="$1"; shift; echo "$*"; }



################### <ERROR CODES> #######################################
declare -A ERROR_CODES

ERROR_CODES["RUN/NO_COMMAND"]=1
ERROR_CODES["RUN/NO_ARG"]=2
ERROR_CODES["RUN/VAR_MISSING"]=3
ERROR_CODES["RUN/DIST_VAR_MISSING"]=4
ERROR_CODES["SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/MISSING_PACKAGE_DIR"]=5
################### </ERROR CODES> ######################################