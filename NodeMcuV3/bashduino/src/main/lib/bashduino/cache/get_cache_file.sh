#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   get cache file path for given library
# Params:
#   $1  | library path
#   $2  | cache filename
# RETURN_VALUE:
#   name of the cache file

required_variables "CACHE_DIR"

require "$1"
local library_path="$1"
require "$2"
local filename="$2"

local cache_dir_abs="${CACHE_DIR}/${library_path}"

mkdir -p "${cache_dir_abs}"

RETURN_VALUE="${cache_dir_abs}/${filename}"