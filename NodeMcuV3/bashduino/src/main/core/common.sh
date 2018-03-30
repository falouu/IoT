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
  errcho "${message} [$(caller)]"
  exit "${ERROR_CODES[${error_id}]}";
}

success(){
    local code="$?"
    [[ "${code}" == "${ERROR_CODES["SYSTEM/COMMAND_NOT_FOUND"]}" ]] && {
        die "Command not found error!" "SYSTEM/COMMAND_NOT_FOUND"
    }
    return "${code}"
}

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

# Params:
#   $1  separator (might be multi-character)
#   $2  array
# Exit policy:
#   never exits
join_by() {
    local d=$1
    shift
    local result="$1"
    shift
    RETURN_VALUE="${result}$(printf "%s" "${@/#/$d}")"
}

# Params:
#   $1  separator (might be multi-character)
#   $2  string to split
# Exit policy:
#   never exits
split_by() {
    local delimiter="$1"
    local str="$2"
    local s="${str}${delimiter}"
    local result=()

    while [[ "$s" ]]; do
        result+=( "${s%%"${delimiter}"*}" );
        s=${s#*"${delimiter}"};
    done;

    RETURN_VALUE=( "${result[@]}" )
}

# Params:
#   $1 value to check for existence
# Returns:
#   null
# Exit policy:
#   die, if checks fails
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

declare -A MAPS
# Exit policy:
#   die, if invalid format
map._get_segments() {
    require "$1"
    local statement="$1"
    local result=()
    [[ "$statement" =~ ^([[:alnum:]]+)(\[(.*)\])*$ ]] || {
        die "Invalid format of map statement" "GENERAL/SYNTAX_ERROR"
    }
    local main_segment="${BASH_REMATCH[1]}"

    result=( "${main_segment}" )

    if [[ "${BASH_REMATCH[2]}" ]]; then
        local index_segment="${BASH_REMATCH[3]}"
        split_by "][" "${index_segment}"
        for index in "${RETURN_VALUE[@]}"; do
            [[ "$index" =~ ^[a-zA-Z_][a-zA-Z0-9]*$ ]] || {
                die "invalid map index: '${index}'" "GENERAL/SYNTAX_ERROR"
            }
            result+=( "${index}" )
        done
    fi
    RETURN_VALUE=( "${result[@]}" )
    return 0

}

# Returns:
#   0  value found, and it is leaf (value returned in RETURN_VALUE)
#   1  value found, and it is not leaf (array of keys returned in RETURN_VALUE)
#   2  value not found
# RETURN_VALUE:
#   value of the statement if found, different types according to return code
map.get() {
    require "$1"
    local statement="$1"

    map._get_var_name_of_statement "${statement}"
    local var_name="${RETURN_VALUE}"

    [[ -v "${var_name}" ]] || [[ -v "${var_name}[@]" ]] || {
        RETURN_VALUE=""
        return 2
    }
    [[ "$(declare -p ${var_name})" =~ "declare -A" ]] && {
        local -n ref="${var_name}"
        RETURN_VALUE=( "${!ref[@]}" )
        return 1
    }
    RETURN_VALUE="${!var_name}"
    return 0
}
map.set() {
    require "$1"
    require "$2"

    local statement="$1"
    local value="$2"

    map._get_segments "${statement}"
    local segments=( "${RETURN_VALUE[@]}" )
    local parent="map_${segments[0]}"
    for segment in "${segments[@]:1}"; do
        [[ -v "${parent}" ]] || {
            #debug "declaring ${parent}"
            declare -g -A "${parent}"
        }
        #debug "${parent}+=( \"${segment}\" )"
        eval "${parent}[\"${segment}\"]=\"DEFINED\""
        parent="${parent}_${segment}"
    done

    declare -g "${parent}"
    local -n pointer="${parent}"
    pointer="${value}"
}

# Params:
#   $1 | map statement
# RETURN_VALUE:
#   value of the statement if found and it is scalar value
# Exit policy:
#   die, if value not set or it is not scalar value
map.get_value_or_die() {
    require "$1"
    local statement="$1"

    map.get "$1"
    local status="$?"
    [[ "${status}" == "0" ]] || {
        die "Expected scalar value for map key: '${statement}'. Found something else!" "GENERAL/INVALID_VALUE_TYPE"
    }
}

# Params:
#   $1 | map statement
# RETURN_VALUE:
#   array of keys of inner map assigned to that map element
# Exit policy:
#   die, if value not set or it is not inner map
map.get_keys_or_die() {
    require "$1"
    local statement="$1"

    map.get "$1"
    local status="$?"
    [[ "${status}" == "1" ]] || {
        die "Expected inner map value for map key: '${statement}'. Found something else!" "GENERAL/INVALID_VALUE_TYPE"
    }
}

# Params:
#   $1 | map statement
# RETURN_VALUE:
#   array of keys of inner map assigned to that map element, or empty array if map element is not set
# Exit policy:
#   die, if value is a scalar
map.get_keys_or_empty() {
    require "$1"
    local statement="$1"

    map.get "$1"
    local status="$?"
    [[ "${status}" == "0" ]] && {
        die "Expected inner map value for map key: '${statement}'. Found scalar value!" "GENERAL/INVALID_VALUE_TYPE"
    }
    [[ "${status}" == "2" ]] && {
        RETURN_VALUE=()
    }
}

# Params:
#   $1 | map statement
# RETURN_VALUE:
#   null
# Exit policy:
#   unknown
map.unset() {
    require "$1"
    local statement="$1"

    map._get_segments "${statement}"
    local segments=( "${RETURN_VALUE[@]}" )

    map._unset_children "${statement}"

    local seg_count="${#segments[@]}"
    local parent_segments=( "${segments[@]:0:${seg_count}-1}" )

    [[ "${#parent_segments[@]}" == "0" ]] && {
        return
    }

    local last_segment="${segments[-1]}"
    map._get_var_name_of_segments "${parent_segments[@]}"
    local parent_var_name="${RETURN_VALUE}"

    eval "unset ${parent_var_name}[\"${last_segment}\"]"
    local -n pointer="${parent_var_name}"
    if [[ "${#pointer[@]}" == "0" ]]; then
        map._get_statement_from_segments "${parent_segments[@]}"
        local parent_statement="${RETURN_VALUE}"
        map.unset "${parent_statement}"
    fi
}

map._unset_children() {
    require "$1"
    local statement="$1"

    map.get "$1"
    local status="$?"
    [[ "${status}" == "1" ]] && {
        local children=( "${RETURN_VALUE[@]}" )
        for child in "${children[@]}"; do
            local child_statement="${statement}[${child}]"
            map._unset_children "${child_statement}"
        done
    }
    map._get_var_name_of_statement "${statement}"
    local var_name="${RETURN_VALUE}"
    unset "${var_name}"
}

map._get_var_name_of_statement() {
    require "$1"
    local statement="$1"

    map._get_segments "${statement}"
    local segments=( "${RETURN_VALUE[@]}" )
    map._get_var_name_of_segments "${segments[@]}"
}

map._get_var_name_of_segments() {
    local segments=( "$@" )
    local var_name="map_${segments[0]}"
    for segment in "${segments[@]:1}"; do
        var_name="${var_name}_${segment}"
    done
    RETURN_VALUE="${var_name}"
}

map._get_statement_from_segments() {
    local segments=( "$@" )
    local statement="${segments[0]}"
    for segment in "${segments[@]:1}"; do
        statement="${statement}[${segment}]"
    done
    RETURN_VALUE="${statement}"
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
ERROR_CODES["GENERAL/SYNTAX_ERROR"]=20
ERROR_CODES["RUN/INVALID_OPTION"]=21
ERROR_CODES["GENERAL/INVALID_VALUE_TYPE"]=22
ERROR_CODES["RUN/OPTION_MISSING"]=23


ERROR_CODES["SYSTEM/COMMAND_NOT_FOUND"]=127


################### </ERROR CODES> ######################################