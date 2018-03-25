#!/usr/bin/env bash
# bash 4.3 required
#
# required system commands:
#   tar
#
# Tested on Arduino 1.8.5

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${DIR}"
BASHDUINO_SRC_ROOT_DIR="${ROOT_DIR}/bashduino/src/main"
CONFIG_DIST_FILE="${ROOT_DIR}/config/config.dist.sh"

source "${DIR}/config/config.sh"
source "${CONFIG_DIST_FILE}"
source "${BASHDUINO_SRC_ROOT_DIR}/core/common.sh"

COMMANDS=(
	"snapshot"
	"shortlist"
	"ide"
	"install_packages"
	"test"
	"help"
)

declare -A COMMAND_HELP
COMMAND_HELP["snapshot"]="create snapshot of files required to download"
COMMAND_HELP["ide"]="run properly configured Arduino IDE"
COMMAND_HELP["install_packages"]="Install required packages"
COMMAND_HELP["shortlist"]="list all commands"
COMMAND_HELP["test"]="run tests"
COMMAND_HELP["help"]="help for a given command. Type: 'help <command>'"

declare -A COMMAND_FILES
COMMAND_FILES["snapshot"]="create_snapshot_arduino_ide_config.sh"
COMMAND_FILES["ide"]="ide.sh"
COMMAND_FILES["install_packages"]="install_packages.sh"
COMMAND_FILES["shortlist"]="shortlist.sh"
COMMAND_FILES["test"]="test.sh"
COMMAND_FILES["help"]="help.sh"

declare -A COMMAND_PARAMS
COMMAND_PARAMS["snapshot"]="COMMAND_PARAMS_SNAPSHOT"

COMMAND_PARAMS_SNAPSHOT=( "COMMAND_PARAMS_SNAPSHOT_CONFIG_DIR" )

declare -A COMMAND_PARAMS_SNAPSHOT_CONFIG_DIR
COMMAND_PARAMS_SNAPSHOT_CONFIG_DIR["name"]="config-dir"
COMMAND_PARAMS_SNAPSHOT_CONFIG_DIR["default"]="default arduino config dir"
COMMAND_PARAMS_SNAPSHOT_CONFIG_DIR["description"]="arduino config directory"


usage() {
	echo "usage:"
	echo "  commands:"
	for command in "${COMMANDS[@]}"; do
		echo "    ${command} - ${COMMAND_HELP[${command}]}"
	done
	echo 
	echo "  If you want autocompletion of these commands, run following command: 'source \"${ROOT_DIR}/autocomplete.sh\"'"
	echo 
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
[[ -z "${COMMAND}" ]] && usage "no command specified" "RUN/NO_COMMAND"
containsElement "${COMMAND}" "${COMMANDS[@]}" || {
	usage "unknown command: ${COMMAND}" "RUN/UNKNOWN_COMMAND"
}

declare -A PARAMS

# TODO: fill PARAMS

source "${BASHDUINO_SRC_ROOT_DIR}/commands/${COMMAND_FILES[${COMMAND}]}"






# while true; do
# 	arg="$1"
# 	shift
# 	if [[ $arg =~ ^--([a-zA-Z-]+)$ ]]; then
# 		name="${BASH_REMATCH[1]}"
# 		value="$1"
# 		shift
# 		if [[ -z "$value" ]]; then
# 			value=true
# 		fi
# 		COMMON_ARGS[$name]="$value"
# 	elif [[ ! -z "$arg" ]]; then
# 		errcho "Invalid option: ${arg}"
# 		exit 1
# 	else
# 		return 0
# 	fi
# done