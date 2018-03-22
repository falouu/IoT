#/usr/bin/env bash
# DO NOT CALL THIS FILE!


CONFIG_DIR="${HOME}/.arduino15"

PACKAGE="esp8266"
ARCH="esp8266"
VERSION="2.4.1"

SNAPSHOT_DIRS=(
	"packages/esp8266/hardware/esp8266/2.4.1/"
	"packages/esp8266/tools/esptool/0.4.13/"
	"packages/esp8266/tools/mkspiffs/0.2.0/"
	"packages/esp8266/tools/xtensa-lx106-elf-gcc/1.20.0-26-gb404fb9-2/"
)

DIST_VARIABLES=( "ARDUINO_CMD" "ARDUINO_IDE_PACKAGES_SNAPSHOT_DIR" )