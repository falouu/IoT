#!/usr/bin/env bash
# DO NOT CALL THIS FILE!

log() {
  local level message log_line command_part
  message="${1}"
  level="${2}"
  [[ -z "${level}" ]] && level="INFO"
  command_part=""
  [[ "${EXECUTED_COMMAND}" ]] && command_part="[${EXECUTED_COMMAND}]:"

  log_line=">> [${level}]:${command_part} ${message}"

  if [[ "${level}" == "ERROR" ]]; then
    >&2 printf "%s\n" "${log_line}"
  else
    printf "%s\n" "${log_line}"
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

# PARAMS:
#   $1  | upstream caller
# OUTPUT:
#   caller string
get_caller() {
    if [[ "$1" ]]; then
        local upstream_caller="$1"
    else
        local upstream_caller="$(caller)"
    fi
    local mcaller=""
    if [[ "${BASHDUINO_EVAL_FILE}" ]]; then
       mcaller="Function: '${BASHDUINO_EVAL_FILE}'"
       local eval_line_pattern="^([0-9]+)[[:space:]].*"
       if [[ "${upstream_caller}" =~ $eval_line_pattern ]]; then
          local eval_line="${BASH_REMATCH[1]}"
          if [[ "${BASHDUINO_EVAL_LINE_OFFSET}" ]]; then
              eval_line="$(( ${eval_line} - ${BASHDUINO_EVAL_LINE_OFFSET} - 3 ))"
          fi
          mcaller+=", line ${eval_line}"
       fi
       mcaller+="; "
    fi

    mcaller+="${upstream_caller}"
    printf "%s" "${mcaller}"
}

# Params:
#   $1  message
#   $2  error id
#   $3  caller - optional
die(){
  local message error_id
  message="$1"
  error_id="$2"
  mcaller="$3"
  [[ -z "${message}" ]] && message="Unknown error"
  [[ -z "${error_id}" ]] && error_id="COMMON/UNKNOWN_ERROR"
  [[ "${mcaller}" ]] || mcaller="$(caller)"
  containsElement "${error_id}" "${!ERROR_CODES[@]}" || {
    message="die(): Unknown error id: '${error_id}' (original error message: '${message}')"
    error_id="COMMON/UNKNOWN_ERROR_ID"
  }
  errcho "${message} [${mcaller}]"
  exit "${ERROR_CODES[${error_id}]}";
}

success(){
    local code="$?"
    [[ "${code}" == "${ERROR_CODES["SYSTEM/COMMAND_NOT_FOUND"]}" ]] && {
        die "Command not found error!" "SYSTEM/COMMAND_NOT_FOUND"
    }
    [[ "${code}" == "${ERROR_CODES["SYSTEM/PIPE_CLOSED"]}" ]] && {
        code=0
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

indent() {
    require "$1"
    local count="$1"
    local output=""
    local prefix="$(repeat " " "${count}")"

    while IFS= read -r; do
        printf "%s\n" "${prefix}${REPLY}"
    done
}

# Params:
#   $1 value to check for existence
#   $2 message when parameter missing - optional
#   $3 caller - optional
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
  if [[ -z ${3+present} ]]; then
    local mcaller="$(get_caller "$(caller)")"
  else
    local mcaller="$3"
  fi
  [[ -z "${value}" ]] && die "${message}" "COMMON/MISSING_PARAM" "${mcaller}"
}

# Params:
#   $1 | value to remove
#   $2 | array variable name
array_remove_first() {
    require "$1"
    require "$2"
    local target="$1"
    local array_var="$2"
    local -n array_remove_first_arr="${array_var}"

    for i in "${!array_remove_first_arr[@]}"; do
        if [[ "${array_remove_first_arr[$i]}" == "${target}" ]]; then
          unset "array_remove_first_arr[$i]"
          return
        fi
    done
}

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
            [[ "$index" =~ ^[a-zA-Z0-9]+$ ]] || {
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
    [[ "$(declare -p ${var_name})" =~ "declare -a" ]] && {
        local -n ref="${var_name}"
        RETURN_VALUE=( "${ref[@]}" )
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
            declare -g -a "${parent}"
        }
        local -n parent_ref="${parent}"
        containsElement "${segment}" "${parent_ref[@]}" || {
            parent_ref+=( "${segment}" )
        }
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

map.get_value_or_empty() {
    require "$1"
    local statement="$1"

    map.get "$1"
    local status="$?"
    [[ "${status}" == "1" ]] && {
        die "Expected scalar value for map key: '${statement}'. Found inner map!" "GENERAL/INVALID_VALUE_TYPE"
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

# Returns:
#   0  is map
#   1  is not map
map.is_map() {
    require "$1"
    local statement="$1"

    map.get "$1"
    local status="$?"
    if [[ "${status}" == "1" ]]; then
        return 0
    else
        return 1
    fi
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

    array_remove_first "${last_segment}" "${parent_var_name}"

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
    require "$1" "missing first parameter to import statement" "$(get_caller "$(caller)")"
    require "$2" "missing second parameter to import statement" "$(get_caller "$(caller)")"
    require "$3" "missing third parameter to import statement" "$(get_caller "$(caller)")"
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
    source "${BASHDUINO_SRC_ROOT_DIR}/core/import_eval.sh"
}

# Docs:
#   run command on new shell
#
# Params:
#   $1 | command
#   $@ | params
#
# Returns:
#   command status code
run_command() {
    require "$1"
    local command="$1"
    shift
    ${ROOT_DIR}/run.sh "${command}" "$@"
    return $?
}


table.print() {
    require "$1"
    local table_var="$1"
    local primary_row
    local items_keys
    local items_count
    local columns
    local header=false
    local vertical_delimiter="|"
    local horizontal_delimiter="-"

    map.get_keys_or_empty "${table_var}[items]"
    items_keys=( "${RETURN_VALUE[@]}" )
    items_count="${#items_keys[@]}"

    if map.is_map "${table_var}[header]"; then
        header=true
    fi

    if [[ "${header}" == "true" ]]; then
        primary_row="[header]"
    else
        [[ "$items_count" == "0" ]] && {
            return
        }
        primary_row="[items][${items_keys[0]}]"
    fi

    declare -A columns_lengths

    map.get_keys_or_die "${table_var}${primary_row}"
    columns=( "${RETURN_VALUE[@]}" )

    for column in "${columns[@]}"; do
        map.get_value_or_empty "${table_var}${primary_row}[${column}]"
        local max_length="${#RETURN_VALUE}"

        for item in "${items_keys[@]}"; do
            map.get_value_or_empty "${table_var}[items][${item}][${column}]"
            local length="${#RETURN_VALUE}"
            if (( $length > $max_length )); then
                max_length="${length}"
            fi
        done

        columns_lengths[${column}]="${max_length}"
    done

    if [[ "${header}" == "true" ]]; then
        local line_length=0
        table._get_row "columns" "columns_lengths" "${table_var}[header]" "${vertical_delimiter}"
        local line="${RETURN_VALUE}"
        local line_length="${#line}"
        printf "${line}\n"
        repeat "${horizontal_delimiter}" "${line_length}"
        printf "\n"
    fi

    for item in "${items_keys[@]}"; do
        table._get_row "columns" "columns_lengths" "${table_var}[items][${item}]" "${vertical_delimiter}"
        local line="${RETURN_VALUE}"
        printf "${line}\n"
    done

    printf "\n"
}

table._get_row() {
    require "$1"
    local -n columns_ref="$1"
    require "$2"
    local -n columns_lengths_ref="$2"
    require "$3"
    local row_statement="$3"
    require "$4"
    local vertical_delimiter="$4"

    local segments=()
    for column in "${columns_ref[@]}"; do
        map.get_value_or_empty "${row_statement}[${column}]"
        local value="${RETURN_VALUE}"
        local value_length="${#value}"
        local column_length="${columns_lengths_ref[${column}]}"
        local spaces_count="$(( column_length - value_length ))"
        local spaces="$(repeat " " ${spaces_count})"
        segments+=( " ${value}${spaces} " )
    done
    join_by "${vertical_delimiter}" "${segments[@]}"
    local line="${RETURN_VALUE}"
    local line_length="${#line}"
    RETURN_VALUE="${line}"
}

# Params:
#   $1 | string to repeat
#   $2 | repeat count
# Output:
#   repeated string
repeat() {
    require "$1"
    require "$2"
    local str="$1"
    local count="$2"
    while (( $count > 0 )); do
        printf "${str}"
        (( count-- ))
    done
}

# Docs:
#   load bashduino dependencies into DEPENDENCIES map
#   For safety reasons, DEPENDENCIES map should be unset when it is no longer needed
#
# Returns:
#   command status code
get_dependencies() {
    source "${BASHDUINO_ROOT_DIR}/dependencies.sh"
    return $?
}

#
#
# Output:
#   dependency output
# Exit policy:
#   exit when dependency not found or on unexpected error
# Returns:
#  <dependency return code> |
call_dependency() {
    required_variables "DEPENDENCIES_DIR"
    require "$1"
    local dep_id="$1"
    require "$2"
    local cmd="$2"

    get_dependencies
    map.get_value_or_die DEPENDENCIES["${dep_id}"][file]
    local dep_file="${RETURN_VALUE}"
    map.unset DEPENDENCIES

    local dep_dir="${DEPENDENCIES_DIR}/${dep_id}"

    [[ -d "${dep_dir}" ]] || die "dependency '${dep_id}' directory not found!" "DEPENDENCIES/NOT_FOUND"

    local cmd_resolved="${cmd/\%depfile\%/$dep_file}"

    pushd "${dep_dir}"
        eval "${cmd_resolved}"
        local return_code="$?"
        [[ "${return_code}" == "${ERROR_CODES["SYSTEM/COMMAND_NOT_FOUND"]}" ]] && {
            errcho "Cannot execute dependency command: '${cmd_resolved}' - command not found"
        }
    popd

    return ${return_code}
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
ERROR_CODES["TEST/TEST_NOT_FOUND"]=24
ERROR_CODES["COMMON/FILE_NOT_FOUND"]=25
ERROR_CODES["SKETCHES/TOO_MANY_SKETCHES"]=26
ERROR_CODES["COMMON/VAR_INVALID_FORMAT"]=27
ERROR_CODES["COMMON/INVALID_OPTION_COMBINATION"]=28
ERROR_CODES["DEPENDENCIES/INSTALLATION_FAILED"]=29
ERROR_CODES["GENERAL/CANNOT_CREATE_DIRECTORY"]=30
ERROR_CODES["DEPENDENCIES/NOT_FOUND"]=31
ERROR_CODES["GET_SNAPSHOT_DIRS/PLATFORM_DEFINITION_NOT_FOUND"]=32


ERROR_CODES["SYSTEM/COMMAND_NOT_FOUND"]=127
ERROR_CODES["SYSTEM/PIPE_CLOSED"]=141


################### </ERROR CODES> ######################################