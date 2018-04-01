#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
    return
}

# Input variables
#   ARGS | map | arguments values
run() {
    local init_file_content="source ~/.bashrc; "
         init_file_content+="ROOT_DIR='${ROOT_DIR}'; BASHDUINO_SRC_ROOT_DIR='${BASHDUINO_SRC_ROOT_DIR}'; "
         init_file_content+="source '${BASHDUINO_SRC_ROOT_DIR}/core/shell_initializer.sh'"

    bash --init-file <(echo "${init_file_content}")
}
