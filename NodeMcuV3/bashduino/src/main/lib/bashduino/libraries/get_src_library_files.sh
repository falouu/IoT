#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   get all src library files (*.h and *.cpp files)
# Params:
#   $1  | library id (directory name)
# Returns:
#   0
# RETURN_VALUE:
#   array of all library *.h and *.cpp files (absolute paths)
# Exit policy:
#   exit only on unexpected error

required_variables "ROOT_DIR"

require "$1"
local library="$1"

local libs_dir="${ROOT_DIR}/src/libraries"

[[ -d "${libs_dir}" ]] || {
    die "src/libraries directory not found in your project!" "COMMON/FILE_NOT_FOUND"
}

local lib_dir="${libs_dir}/${library}"

[[ -d "${lib_dir}" ]] || {
    die "library '${library}' not found in your src dir!" "COMMON/FILE_NOT_FOUND"
}

local lib_src_dir="${lib_dir}/src"

[[ -d "${lib_src_dir}" ]] || {
    die "'src' directory not found in library '${library}' directory!" "COMMON/FILE_NOT_FOUND"
}

local files=( "${lib_src_dir}"/*.h )
files+=( "${lib_src_dir}"/*.cpp )

local count="${#files[@]}"

if (( count < 1 )); then
    die "There is no source files for library '${library}'" "SKETCHES/TOO_MANY_SKETCHES"
fi

RETURN_VALUE=( "${files[@]}" )