#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
    required_variables "ARDUINO_CMD"

    map.set PARAMS[sketch][name] "sketch"
    map.set PARAMS[sketch][description] "sketch to run (run 'ide --sketch-list' command for available sketches)"
    map.set PARAMS[sketch][defaultDescription] "default sketch, defined by DEFAULT_SKETCH variable in project config"
    map.set PARAMS[sketch][required] "false"
    map.set PARAMS[sketch][valuePlaceholder] "sketch module name"
}

# Input variables
#   ARGS | map | arguments values
run() {
    import "bashduino/sketches/get_sketch_file" as "get_sketch_file"
    import "bashduino/ide/prepare_ide" as "prepare_ide"

    local sketch="${DEFAULT_SKETCH}"
    [[ "${ARGS[sketch]}" ]] && {
        sketch="${ARGS[sketch]}"
    }
    require "${sketch}" "Select sketch to run or define default sketch in configuration (run with --help option for more info)"

    get_sketch_file "${sketch}"
    local sketch_file="${RETURN_VALUE}"

    prepare_ide
    success || {
        die "Preparing Arduino IDE failed"
    }

    log "Uploading module '${sketch}'"

    ${ARDUINO_CMD} --upload "${sketch_file}"
}