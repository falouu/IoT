#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

eval "
    ${target_alias}() {
       BASHDUINO_EVAL_FILE_OLD="\${BASHDUINO_EVAL_FILE}"; BASHDUINO_EVAL_FILE="${fq_name}"
       BASHDUINO_EVAL_LINE_OFFSET_OLD="\${BASHDUINO_EVAL_LINE_OFFSET}"; BASHDUINO_EVAL_LINE_OFFSET="\${LINENO}"
       ${function_body}
       BASHDUINO_EVAL_FILE="\${BASHDUINO_EVAL_FILE_OLD}"
       BASHDUINO_EVAL_LINE_OFFSET="\${BASHDUINO_EVAL_LINE_OFFSET_OLD}"
    }
"