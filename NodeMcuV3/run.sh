#/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${DIR}"
CONFIG_DIST_FILE="${DIR}/config/config.dist.sh"

source "${DIR}/config/config.sh"
source "${CONFIG_DIST_FILE}"
source "${DIR}/lib/common.sh"

COMMANDS=(
	"snapshot"
)

declare -A COMMAND_HELP
COMMAND_HELP["snapshot"]="create snapshot of files required to download"

declare -A COMMAND_FILES
COMMAND_FILES["snapshot"]="scripts/create_snapshot_arduino_ide_config.sh"

usage() {
	echo "usage:"
	echo "  commands:"
	for command in "${COMMANDS[@]}"; do
		echo "    ${command} - ${COMMAND_HELP[${command}]}"
	done
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
[[ -z "$COMMAND" ]] && usage "no command specified" "RUN/NO_COMMAND"

source "${DIR}/${COMMAND_FILES[${COMMAND}]}"






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