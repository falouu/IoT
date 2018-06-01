#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   get sketch file name by sketch module name
# Returns:
#   0
# RETURN_VALUE:
#   sketch file path
# Exit policy:
#   exit only on unexpected error
#

require "$1"
local module="$1"

local src_dir="${ROOT_DIR}/src/sketches"

[[ -d "${src_dir}" ]] || {
    die "src/sketches directory not found in your project!" "COMMON/FILE_NOT_FOUND"
}

local src_module_dir="${src_dir}/${module}"

[[ -d "${src_dir}" ]] || {
    die "module '${module}' not found in your src dir!" "COMMON/FILE_NOT_FOUND"
}

local sketches=("${src_module_dir}"/*.ino)

local count="${#sketches[@]}"

if (( count > 1 )); then
    die "There is more than one sketch in module '${module}'!" "SKETCHES/TOO_MANY_SKETCHES"
fi

local sketch_file="${sketches[0]}"

[[ -f "${sketch_file}" ]] || {
    die "Not found any sketches in module '${module}'" "COMMON/FILE_NOT_FOUND"
}

RETURN_VALUE="${sketch_file}"