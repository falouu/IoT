#!/usr/bin/env bash
# bash 4.3 required
#
# required system commands:
#   tar, mv, cp, curl
#
# Tested on Arduino 1.8.5

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${DIR}"
BASHDUINO_ROOT_DIR="${ROOT_DIR}/bashduino"
BASHDUINO_SRC_ROOT_DIR="${BASHDUINO_ROOT_DIR}/src/main"
CONFIG_DIST_FILE="${ROOT_DIR}/config/config.dist.sh"

source "${DIR}/config/config.sh"
source "${CONFIG_DIST_FILE}"
source "${BASHDUINO_SRC_ROOT_DIR}/core/variables_initializer.sh"
source "${BASHDUINO_SRC_ROOT_DIR}/core/common.sh"

COMMANDS=(
	"snapshot"
	"shortlist"
	"ide"
	"install_packages"
	"install_dependencies"
	"test"
	"shell"
	"help"
)

declare -A COMMAND_HELP
COMMAND_HELP["snapshot"]="create snapshot of files required to download"
COMMAND_HELP["ide"]="run properly configured Arduino IDE"
COMMAND_HELP["install_packages"]="Install required packages"
COMMAND_HELP["install_dependencies"]="Install required bashduino dependencies"
COMMAND_HELP["shortlist"]="list all commands"
COMMAND_HELP["test"]="run tests"
COMMAND_HELP["shell"]="run friendly shell with autocompletion"
COMMAND_HELP["help"]="help for a given command. Type: 'help --command <command>'"

declare -A COMMAND_FILES
COMMAND_FILES["snapshot"]="create_snapshot_arduino_ide_config.sh"
COMMAND_FILES["ide"]="ide.sh"
COMMAND_FILES["install_packages"]="install_packages.sh"
COMMAND_FILES["install_dependencies"]="install_dependencies.sh"
COMMAND_FILES["shortlist"]="shortlist.sh"
COMMAND_FILES["test"]="test.sh"
COMMAND_FILES["shell"]="shell.sh"
COMMAND_FILES["help"]="help.sh"

usage() {
	echo "usage:"
	echo "  commands:"
	for command in "${COMMANDS[@]}"; do
		echo "    ${command} - ${COMMAND_HELP[${command}]}"
	done
	echo
	echo "  If you want autocompletion of these commands, run following command: '${ROOT_DIR}/run.sh shell'"
	echo
}

usage_and_die() {
	usage
	die "$1" "$2"
}

required_variables() {
	while true; do
		local var_name="$1"
		shift
		[[ -z "${var_name}" ]] && return
		get_var "${var_name}"
		val="${RETURN_VALUE}"
		[[ -z "${val}" ]] && {
			if containsElement "${var_name}" "${DIST_VARIABLES[@]}"; then
				[[ -e "${CONFIG_DIST_FILE}" ]] || {
					cp "${DIR}/config/config.dist.sh.template" "${CONFIG_DIST_FILE}"
				}
				die "You have to provide variable '${var_name}' in file ${CONFIG_DIST_FILE}" "RUN/DIST_VAR_MISSING"
			fi
			die "required variable is missing: ${var_name}" "RUN/VAR_MISSING"
		}

	done
}

get_var() {
	arg="$1"
	[[ -z "$var_name" ]] && die "Specify variable name!" "RUN/NO_ARG"
	val="${!arg}"
	RETURN_VALUE="${val}"
}

COMMAND="$1"
shift
_validate_command() {
    local command="$1"
    [[ -z "${command}" ]] && usage_and_die "no command specified" "RUN/NO_COMMAND"
    containsElement "${command}" "${COMMANDS[@]}" || {
        usage_and_die "unknown command: ${command}" "RUN/UNKNOWN_COMMAND"
    }
}

_validate_command "${COMMAND}"

declare -A ARGS
declare -A ARGS_RAW

option_pattern="^--([a-zA-Z-]+)$"
while true; do
    [[ $# -eq 0 ]] && break
    arg="$1"
    shift
    if [[ $arg =~ $option_pattern ]]; then
        name="${BASH_REMATCH[1]}"
        value="$1"
        if [[ $value =~ $option_pattern ]]; then
            value=""
        else
            shift
        fi

        if [[ -z "${value}" ]]; then
            value=true
        fi
        ARGS_RAW[$name]="${value}"
    elif [[ "${arg}" ]]; then
        die "Invalid option: '${arg}'. Every options must start with '--' prefix" "RUN/INVALID_OPTION"
    fi
done

_execute_command() {
    require "$1"
    local command="$1"
    _setup_command "${command}"
    if [[ "${ARGS[help]}" == "true" ]]; then
        run_command "help" "--command" "${command}"
        return
    fi

    declare -g EXECUTED_COMMAND="${command}"

    run
    local status="$?"
    [[ "${status}" == "${ERROR_CODES["SYSTEM/COMMAND_NOT_FOUND"]}" ]] && {
        die "run() method not defined for command '${command}'" "SYSTEM/COMMAND_NOT_FOUND"
    }
    return "${status}"
}

_setup_command() {
    require "$1"
    local command="$1"
    source "${BASHDUINO_SRC_ROOT_DIR}/commands/${COMMAND_FILES[${command}]}"

    # Output variables:
    #   PARAM_BY_NAME | associative array | must be declared prior
    get_param_names() {
        map.get_keys_or_empty PARAMS
        local status="$?"
        local params_ids=( "${RETURN_VALUE[@]}" )

        for param_id in "${params_ids[@]}"; do
            map.get_value_or_die PARAMS[${param_id}][name]
            PARAM_BY_NAME["${RETURN_VALUE}"]="${param_id}"
        done
    }

    setup
    [[ "$?" == "${ERROR_CODES["SYSTEM/COMMAND_NOT_FOUND"]}" ]] && {
        die "setup() method not defined for command '${command}'" "SYSTEM/COMMAND_NOT_FOUND"
    }

    map.set PARAMS[help][name] "help"
    map.set PARAMS[help][description] "show help for command"
    map.set PARAMS[help][required] "false"

    declare -A PARAM_BY_NAME
    get_param_names

    for arg in "${!ARGS_RAW[@]}"; do
        containsElement "${arg}" "${!PARAM_BY_NAME[@]}" || {
            die "Unexpected option: '--${arg}'" "RUN/INVALID_OPTION"
        }
    done

    map.get_keys_or_empty PARAMS
    local param_ids=( "${RETURN_VALUE[@]}" )
    for param_id in "${param_ids[@]}"; do
        map.get_value_or_die PARAMS[${param_id}][required]
        local is_required="${RETURN_VALUE}"

        map.get_value_or_die PARAMS[${param_id}][name]
        local param_name="${RETURN_VALUE}"
        if [[ "${ARGS_RAW[${param_name}]}" ]]; then
            ARGS[${param_id}]="${ARGS_RAW[${param_name}]}"
        else
            if [[ "${is_required}" == "true" ]]; then
                die "Option '--${param_name}' is required and is not set!" "RUN/OPTION_MISSING"
            fi
        fi
    done
}

_execute_command "${COMMAND}"