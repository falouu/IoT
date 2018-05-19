cmake_minimum_required(VERSION 3.10)  # CMake version check
project(NodeMcuV3)                    # Create project
set(CMAKE_CXX_STANDARD 11)            # Enable c++11 standard

include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/libraries/ESP8266WiFi/src)
include_directories($ENV{HOME}/.arduino15/packages/esp8266/hardware/esp8266/2.4.1/cores/esp8266/)

SET(SOURCE_FILES
    src/CaptivePortal/CaptivePortal.ino
)

add_executable(NodeMcuV3 ${SOURCE_FILES})

set_source_files_properties(${SOURCE_FILES} PROPERTIES LANGUAGE CXX)
set_target_properties(NodeMcuV3 PROPERTIES LINKER_LANGUAGE CXX)