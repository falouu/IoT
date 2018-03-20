#/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!



${ARDUINO_CMD} --install-boards ${PACKAGE}:${ARCH}:${VERSION} --pref boardsmanager.additional.urls=http://arduino.esp8266.com/stable/package_esp8266com_index.json





#--install-boards package name:platform architecture[:version]

# --install-boards esp8266:esp8266:2.4.1


# boardsmanager.additional.urls=http://arduino.esp8266.com/stable/package_esp8266com_index.json


# --pref name=value

# --pref boardsmanager.additional.urls=http://arduino.esp8266.com/stable/package_esp8266com_index.json