#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
    required_variables "PORT" "ARDUINO_CMD"

    map.set PARAMS[sketch][name] "sketch"
    map.set PARAMS[sketch][description] "sketch to run"
    map.set PARAMS[sketch][defaultDescription] "default sketch, defined by DEFAULT_SKETCH variable in project config"
    map.set PARAMS[sketch][required] "false"
    map.set PARAMS[sketch][valuePlaceholder] "sketch module name"
}

# Input variables
#   ARGS | map | arguments values
run() {
    import "bashduino/preferences/get_preferences" as "get_preferences"
    import "bashduino/preferences/apply_preferences" as "apply_preferences"
    import "bashduino/sketches/get_sketch_file" as "get_sketch_file"

    local sketch="${DEFAULT_SKETCH}"
    [[ "${ARGS[sketch]}" ]] && {
        sketch="${ARGS[sketch]}"
    }
    require "${sketch}" "Select sketch to run or define default sketch in configuration (run with --help option for more info)"

    get_sketch_file "${sketch}"
    local sketch_file="${RETURN_VALUE}"

    if [[ ! -e "${PORT}" ]]; then
        die "'${PORT}' file does not exists" "IDE/PORT_NOT_EXISTS"
    fi

    if [[ ! -c "${PORT}" ]]; then
        die "'${PORT}' file is not a device!" "IDE/PORT_NOT_DEVICE"
    fi

    local PORT_FILE_OWNER_GROUP=$(stat --format %g "${PORT}")

    local PORT_FILE_OWNER_GROUP_NAME=$(getent group ${PORT_FILE_OWNER_GROUP} | cut -f1 -d':')

    echo "'${PORT}' file is owned by group '${PORT_FILE_OWNER_GROUP_NAME}'"


    if [[ ! -w "${PORT}" ]]; then
        id -G "$USER" | grep -qw "${PORT_FILE_OWNER_GROUP}"
        success || {
            log "Current user (${USER}) does not belong to group '${PORT_FILE_OWNER_GROUP_NAME}', so the user can't access the file"
            echo "Do you want to add user '${USER}' to group '${PORT_FILE_OWNER_GROUP_NAME}'?"
            yes_or_no || die "No is no" 4

            sudo usermod -a -G "${PORT_FILE_OWNER_GROUP_NAME}" "${USER}"
            success || {
                die "Cannot add user '${USER}' to group '${PORT_FILE_OWNER_GROUP_NAME}'" 5
            }

            log "You have to logout and login to get the group permissions!"
            exit 0
        }


        die "'${PORT}' file is not writable by current user!" 3
    else
        log "Checking permissions... OK"
    fi

    run_command "install_packages"
    success || {
        die "Installing packages FAILED"
    }

    unset prefs
    declare -A prefs
    get_preferences prefs

    prefs["boardsmanager.additional.urls"]="${BOARDSMANAGER_URL}"
    prefs["serial.port"]="${PORT}"
    # serial.port.file=ttyUSB0
    # serial.port.iserial=null

    apply_preferences prefs
    unset prefs

    log "Running module '${sketch}'"
    ${ARDUINO_CMD} "${sketch_file}"
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
