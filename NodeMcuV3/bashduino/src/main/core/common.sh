#!/usr/bin/env bash
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
debug() { log "$@" "DEBUG"; }
errcho(){  log "$@" "ERROR"; }
# usage: containsElement "a string" "${array[@]}"
containsElement() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}
die(){
  local message error_id
  message="$1"
  error_id="$2"
  [[ -z "${message}" ]] && message="Unknown error"
  [[ -z "${error_id}" ]] && error_id="COMMON/UNKNOWN_ERROR"
  containsElement "${error_id}" "${!ERROR_CODES[@]}" || {
    message="die(): Unknown error id: '${error_id}' (original error message: '${message}')"
    error_id="COMMON/UNKNOWN_ERROR_ID"
  }
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

# Docs:
#   Import functions from bashduino/src/lib directory
#
# Params:
#   $1  fully qualified identifier of function to be imported
#   $2  fixed string: "as"
#   $3  alias name to be created for that function
#
# Returns:
#   null
import() {
    require "$1"
    require "$2"
    require "$3"
    [[ "$2" == "as" ]] || {
        die "improper use of import(). Second argument must be 'as'" "COMMON/INVALID_PARAM"
    }
    local fq_name="$1"
    local target_alias="$3"

    local function_abs_path="${BASHDUINO_SRC_ROOT_DIR}/lib/${fq_name}.sh"

    [[ -f "${function_abs_path}" ]] || {
        die "Cannot import: file '${function_abs_path}' does not exist" "COMMON/IMPORT_LIB_NOT_EXISTS"
    }
    local function_body="$(<${function_abs_path})"
    eval "
        ${target_alias}() {
           ${function_body}
        }
    "
}

# Docs:
#   run command on new shell
#
# Params:
#   $1  command
#
# Returns:
#   command status code
run_command() {
    require "$1"
    local command="$1"
    ${ROOT_DIR}/run.sh "${command}"
    return $?
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
ERROR_CODES["IDE/PORT_NOT_EXISTS"]=11
ERROR_CODES["IDE/PORT_NOT_DEVICE"]=12
ERROR_CODES["IDE/UNKNOWN_ERROR"]=13
ERROR_CODES["COMMON/UNKNOWN_ERROR_ID"]=14
ERROR_CODES["COMMON/INVALID_PARAM"]=15
ERROR_CODES["COMMON/IMPORT_LIB_NOT_EXISTS"]=16
ERROR_CODES["IDE/CREATE_SNAPSHOTS_FAILED"]=17
ERROR_CODES["INSTALL_PACKAGES/NO_SNAPSHOT_FILE"]=18
ERROR_CODES["INSTALL_PACKAGES/UNPACK_FAILED"]=19



################### </ERROR CODES> ######################################