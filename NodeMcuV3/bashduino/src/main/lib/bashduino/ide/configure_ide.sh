#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   configure arduino ide for compilatoion
# Returns:
#   0
# Exit policy:
#   exit with error if preparing failed
required_variables "PORT" "BOARDSMANAGER_URL"

import "bashduino/preferences/get_preferences" as "get_preferences"
import "bashduino/preferences/apply_preferences" as "apply_preferences"

run_command "install_packages"
success || {
    die "Installing packages FAILED"
}

unset prefs
declare -A prefs
get_preferences prefs

prefs["boardsmanager.additional.urls"]="${BOARDSMANAGER_URL}"
prefs["serial.port"]="${PORT}"

apply_preferences prefs
unset prefs