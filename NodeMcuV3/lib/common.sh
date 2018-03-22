#/usr/bin/env bash
# DO NOT CALL THIS FILE!

log() {
  local level message log_line
  message="${1}"
  level="${2}"
  [[ -z "${level}" ]] && level="INFO"
  log_line=">> [${level}]: ${message}"

  if [[ "${level}" == "ERROR" ]]; then
    >&2 echo "${log_line}"
  else
    echo "${log_line}"
  fi
}
errcho(){  log "$@" "ERROR"; }
die(){
  local message error_id
  message="$1"
  error_id="$2"
  [[ -z "${message}" ]] && message="Unknown error"
  [[ -z "${error_id}" ]] && error_id="COMMON/UNKNOWN_ERROR"
  errcho "${message}"
  exit "${ERROR_CODES[${error_id}]}";
}
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
containsElement() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}
function join_by { local IFS="$1"; shift; echo "$*"; }

# returns: null
require() {
  [[ -z ${1+present} ]] && die "require(): missing parameter 1" "COMMON/MISSING_PARAM"
  local value="$1"
  if [[ -z ${2+present} ]]; then
    local message="Missing parameter"
  else
    local message="$2"
  fi
  [[ -z "${value}" ]] && die "${message}" "COMMON/MISSING_PARAM"
}


################### <ERROR CODES> #######################################
declare -A ERROR_CODES

ERROR_CODES["RUN/NO_COMMAND"]=1
ERROR_CODES["RUN/NO_ARG"]=2
ERROR_CODES["RUN/VAR_MISSING"]=3
ERROR_CODES["RUN/DIST_VAR_MISSING"]=4
ERROR_CODES["SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/MISSING_PACKAGE_DIR"]=5
ERROR_CODES["RUN/UNKNOWN_COMMAND"]=6
ERROR_CODES["COMMON/MISSING_PARAM"]=7
ERROR_CODES["SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/MISSING_SNAPSHOTS_DIR"]=8
ERROR_CODES["SCRIPTS/CREATE_SNAPSHOT_ARDUINO_IDE_CONFIG/ARCHIVE_CREATE_FAILED"]=9
ERROR_CODES["COMMON/UNKNOWN_ERROR"]=10

################### </ERROR CODES> ######################################