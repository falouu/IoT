#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   get all available sketches (module names)
# Returns:
#   0
# RETURN_VALUE:
#   array of sketches (modules)
# Exit policy:
#   exit only on unexpected error
#
required_variables "ROOT_DIR"

local src_dir="${ROOT_DIR}/src/sketches"

local sketches=()
pushd "${src_dir}" > /dev/null
for dir in */; do
    local files=( "$dir"/* )

    for file in "${files[@]}"; do
        if [[ -f "${file}" ]] && [[ "${file}" == *.ino ]]; then
            sketches+=( "${dir:0:-1}" )
            break
        fi
    done
done
popd > /dev/null

RETURN_VALUE=( "${sketches[@]}" )