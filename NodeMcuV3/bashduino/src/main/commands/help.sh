#!/usr/bin/env bash

# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
    map.set PARAMS[command][name] "command"
    map.set PARAMS[command][description] "show help for specific command"
    map.set PARAMS[command][required] "false"
}

# Input variables
#   ARGS | map | arguments values
run() {
    _execute_help() {
        if [[ "${ARGS[command]}" ]]; then
            _execute_help_for_command "${ARGS[command]}"
        else
            usage
        fi
    }

    _execute_help_for_command() {
        require "$1"
        local command="$1"
        unset ARGS
        declare -A ARGS



        _setup_command "${command}"

        echo "Help for command '${command}':"
        echo "  Options:"
        map.get_keys_or_empty PARAMS
        local param_ids=( "${RETURN_VALUE[@]}" )
        for param_id in "${param_ids[@]}"; do
            map.get_value_or_die PARAMS[${param_id}][name]
            local param_name="${RETURN_VALUE}"
            echo "    --${param_name}"
        done
    }

    _execute_help
}