#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
    required_variables "ARDUINO_CMD"

    map.set PARAMS[sketch][name] "sketch"
    map.set PARAMS[sketch][description] "sketch to run"
    map.set PARAMS[sketch][defaultDescription] "default sketch, defined by DEFAULT_SKETCH variable in project config"
    map.set PARAMS[sketch][required] "false"
    map.set PARAMS[sketch][valuePlaceholder] "sketch module name"

    map.set PARAMS[list][name] "sketch-list"
    map.set PARAMS[list][description] "list all available sketches"
    map.set PARAMS[list][required] "false"
}

# Input variables
#   ARGS | map | arguments values
run() {
    ide_command_run_sketch() {
        import "bashduino/sketches/get_sketch_file" as "get_sketch_file"
        import "bashduino/ide/prepare_ide" as "prepare_ide"

        local sketch="${DEFAULT_SKETCH}"
        [[ "$1" ]] && {
            sketch="${1}"
        }
        require "${sketch}" "Select sketch to run or define default sketch in configuration (run with --help option for more info)"

        get_sketch_file "${sketch}"
        local sketch_file="${RETURN_VALUE}"

        prepare_ide
        success || {
            die "Preparing Arduino IDE failed"
        }

        log "Running module '${sketch}'"
        ( ${ARDUINO_CMD} "${sketch_file}" > arduino.log 2> arduino_error.log & )
    }

    ide_command_list_sketches() {
        import "bashduino/sketches/get_sketches" as "get_sketches"
        get_sketches
        local sketches=( "${RETURN_VALUE[@]}" )
        if [[ "${#sketches[@]}" == "0" ]]; then
            errcho "not found any sketches!"
            return "${ERROR_CODES["COMMON/FILE_NOT_FOUND"]}"
        fi
        for sketch in "${sketches[@]}"; do
            printf "%s\n" "${sketch}"
        done
    }


    local list_sketches="${ARGS[list]}"
    local sketch="${ARGS[sketch]}"

    if [[ "${list_sketches}" ]] && [[ "${sketch}" ]]; then
        die "Only one of the options: --sketch, --sketch-list is allowed" "COMMON/INVALID_OPTION_COMBINATION"
    fi

    if [[ "${list_sketches}" ]]; then
        ide_command_list_sketches
        return $?
    fi

    ide_command_run_sketch "${sketch}"
    return $?




}

#update_config_dir_from_snapshot() {
#
#}
#
#update_config_dir_from_snapshot



# Dodaj definicję mikrokontrolera esp8266
# http://arduino.esp8266.com/stable/package_esp8266com_index.json
# * PReferences -> Additional Platforms URL
# * Narzędzia -> Płytka -> Menadżer płytek -> esp8266 -> install
# * Narzędzia -> Płytka -> NodeMCU 1.0 (ESP-12E Module)
# * Narzędzia -> Port -> $PORT

# preferencje Arduino IDE są zapisane tutaj: ~/.arduino15

### Preferences to set
# board=nodemcuv2
# custom_CpuFrequency=nodemcuv2_80
# custom_FlashErase=nodemcuv2_none
# custom_FlashSize=nodemcuv2_4M1M
# custom_LwIPVariant=nodemcuv2_v2mss536
# custom_UploadSpeed=nodemcuv2_115200

# serial.port=/dev/ttyUSB0
# serial.port.file=ttyUSB0
# serial.port.iserial=null

# target_package=esp8266
# target_platform=esp8266


### Preferences MAYBE to set
# custom_Debug=nodemcuv2_Disabled
# custom_DebugLevel=nodemcuv2_None____

## Needed files
### package_esp8266com_index.json
## Need to refresh packages (package_index.json) and libraries (library_index.json)
### but these files aren't changed by installing additional packages, so no need to modify them
