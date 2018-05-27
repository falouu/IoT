#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   get hardware dir
# Returns:
#   0  | if no error
# RETURN_VALUE
#   string | hardware snapshot directory
# Exit policy:
#   - exit on unexpected error
required_variables "PACKAGE" "ARCH" "VERSION"

RETURN_VALUE="packages/${PACKAGE}/hardware/${ARCH}/${VERSION}/"