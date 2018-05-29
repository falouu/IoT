cmake_minimum_required(VERSION 3.10)  # CMake version check
project(NodeMcuV3)                    # Create project
set(CMAKE_CXX_STANDARD 11)            # Enable c++11 standard


include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/cores/esp8266/)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ArduinoOTA/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/DNSServer/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/EEPROM/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/esp8266/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ESP8266AVRISP/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ESP8266HTTPClient/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ESP8266httpUpdate/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ESP8266HTTPUpdateServer/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ESP8266LLMNR/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ESP8266mDNS/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ESP8266NetBIOS/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ESP8266SSDP/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ESP8266WebServer/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ESP8266WiFi/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ESP8266WiFiMesh/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/Ethernet/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/GDBStub/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/Hash/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/SD/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/Servo/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/SoftwareSerial/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/SPI/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/SPISlave/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/TFT_Touch_Shield_V2/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/Ticker/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/Wire/src)

SET(SOURCE_FILES
  src/BlinkBuiltinLed/BlinkBuiltinLed.ino
  src/BlinkLedOnRequest/BlinkLedOnRequest.ino
  src/CaptivePortal/CaptivePortal.ino
)

add_executable(NodeMcuV3 ${SOURCE_FILES})

set_source_files_properties(${SOURCE_FILES} PROPERTIES LANGUAGE CXX)
set_target_properties(NodeMcuV3 PROPERTIES LINKER_LANGUAGE CXX)