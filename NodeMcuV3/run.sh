#/usr/bin/env bash

source "lib/common.sh"

COMMANDS=(
	"snapshot"
)

declare -A COMMAND_HELP

COMMAND_HELP["snapshot"]="create snapshot of files required to download"

usage() {
	echo "usage:"
	echo "  commands:"
	for command in "${COMMANDS[@]}"; do
		echo "    ${command} - ${COMMAND_HELP[${command}]}"
	done
	die "$1" "$2"
}

while true; do
	arg="$1"
	shift
	[[ -z "$arg" ]] && usage "no command specified" "RUN/NO_COMMAND"
done


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