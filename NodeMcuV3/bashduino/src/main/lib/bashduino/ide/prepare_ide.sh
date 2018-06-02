#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Docs:
#   prepare arduino ide (configure before running for uploading)
# Returns:
#   0
# Exit policy:
#   exit with error if preparing failed
#
import "bashduino/ide/configure_port" as "configure_port"
import "bashduino/ide/configure_ide" as "configure_ide"

configure_port
configure_ide