#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
    required_variables "PORT" "SERIAL_BAUD_RATE"
}

# Input variables
#   ARGS | map | arguments values
run() {
   log "Monitoring serial port '${PORT}' with baudrate ${SERIAL_BAUD_RATE}"

   try_read() {
       lsof "${PORT}" > /dev/null 2>/dev/null
       if [[ "$?" == "0" ]]; then
         local busy="true"
       else
         local busy="false"
       fi

       if [[ "${busy}" == "true" ]]; then
          log "Serial port is busy, waiting..."
          return 1
       fi

       stty -F "${PORT}" "${SERIAL_BAUD_RATE}"
       cat "${PORT}"
   }

   while true; do
       try_read
       sleep 10
   done
}