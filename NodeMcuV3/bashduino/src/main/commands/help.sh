#!/usr/bin/env bash

# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
    map.set PARAMS[command][name] "command"
    map.set PARAMS[command][description] "show help for specific command"
    map.set PARAMS[command][required] "false"
    map.set PARAMS[command][valuePlaceholder] "command"
    map.set PARAMS[command][defaultDescription] "show general usage"
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
        unset ARGS_RAW
        declare -A ARGS
        map.unset PARAMS

        _setup_command "${command}"

        echo "Help for command '${command}':"
        echo "  Options:"
        map.get_keys_or_empty PARAMS
        local param_ids=( "${RETURN_VALUE[@]}" )
        for param_id in "${param_ids[@]}"; do
            map.get_value_or_die PARAMS[${param_id}][name]
            local param_name="${RETURN_VALUE}"
            map.get_value_or_die PARAMS[${param_id}][description]
            local param_description="${RETURN_VALUE}"
            map.get_value_or_die PARAMS[${param_id}][required]
            local param_required="${RETURN_VALUE}"
            map.get_value_or_empty PARAMS[${param_id}][defaultDescription]
            local param_default_description="${RETURN_VALUE}"
            map.get_value_or_empty PARAMS[${param_id}][valuePlaceholder]
            local param_value_placeholder="${RETURN_VALUE}"

            if [[ "${param_required}" == "true" ]]; then
                local param_required_string=" [required]"
            else
                if [[ "${param_default_description}" ]]; then
                    local param_required_string=" [optional; if not set: ${param_default_description}]"
                else
                    local param_required_string=" [optional]"
                fi

            fi

            local value_placeholder_string=""
            if [[ "${param_value_placeholder}" ]]; then
                value_placeholder_string="<${param_value_placeholder}>"
            fi

            echo "    --${param_name} ${value_placeholder_string}  |  ${param_description}${param_required_string}"
        done
    }

    _execute_help
}