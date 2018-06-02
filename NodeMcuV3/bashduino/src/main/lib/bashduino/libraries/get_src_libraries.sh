#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   get all available libraries (cpp source libraries, not bashduino libraries)
# Returns:
#   0
# RETURN_VALUE:
#   array of libraries (library directory names)
# Exit policy:
#   exit only on unexpected error
required_variables "ROOT_DIR"

local lib_dir="${ROOT_DIR}/src/libraries"

local libraries=()
pushd "${lib_dir}" > /dev/null
for dir in */; do
    local files=( "$dir"/* )
    libraries+=( "${dir:0:-1}" )
done
popd > /dev/null

RETURN_VALUE=( "${libraries[@]}" )