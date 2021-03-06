# NodeMcu V3 Wiki


## esp8266

### Vocabulary

* `SPIFFS` - file system used on esp8266 

### Info

### Links


## Arduino

### Configuration
* preferences and packages localization: `~/.arduino15`

### Links

* Language reference: https://www.arduino.cc/reference/en/
* More technical reference: https://github.com/arduino/Arduino/wiki
* Specification of third-party platforms format:
    * https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5-3rd-party-Hardware-specification 
    * How Arduino determine what to include for compilation: https://github.com/arduino/Arduino/wiki/Build-Process#compilation


## esp8266 platform on Arduino IDE

### Macros

* `LED_BUILTIN`
	* Not working on NodeMcu V3 (or ESP8266-12E/F in general)

	  For NodeMcu V3 define:

	  ```c
	  #define LED_BUILTIN 2
	  ```

### Docs

* Main docs: https://github.com/esp8266/Arduino/tree/master/doc

### Info
* C++ code is compiled using `c++11` standard (see `esp8266/hardware/esp8266/2.4.1/platform.txt` file and search 
  for `compiler.cpp.flags` property, you will see `-std=c++11` option) 

### Preferences

* `custom_FlashErase=nodemcuv2_none` - you can set this to other values (TODO: check what values), to erase WiFi 
   credentials on the next upload

### Sources

Sources for API are defined in: https://github.com/esp8266/Arduino/blob/master/cores/esp8266/ 

examples:
* signature of function `digitalWrite` is here: https://github.com/esp8266/Arduino/blob/master/cores/esp8266/core_esp8266_wiring_digital.c
* api of `Print` class (inherited by many other classes, like `Serial`): https://github.com/esp8266/Arduino/blob/master/cores/esp8266/Print.h


### Code Examples

* Connecting to WiFi by WPS:
  * https://gist.github.com/copa2/fcc718c6549721c210d614a325271389
  * https://github.com/esp8266/Arduino/issues/1958
* Captive Portal
  * another option to setup WiFi credentials - first, ESP will get into
    AP mode. You can connect to its temporary network from other device, set
    a target network credentials. Then ESP will get into client mode
    and connect to the target network
  * https://github.com/esp8266/Arduino/blob/master/libraries/DNSServer/examples/CaptivePortal/CaptivePortal.ino
  * https://github.com/esp8266/Arduino/blob/master/libraries/DNSServer/examples/CaptivePortalAdvanced/CaptivePortalAdvanced.ino

### Utils

* Flash config checker: https://github.com/esp8266/Arduino/blob/master/libraries/esp8266/examples/CheckFlashConfig/CheckFlashConfig.ino




## NodeMcu V3 with Arduino IDE

### Config (based on my unit)

* Flash size: 4M (1M SPIFFS) //(3M SPIFFS also works)
* lwIP Variant: v2 Lower Memory (TODO: verify)
* CPU Frequency: 80 MHz
* Upload Speed: 115200

### Board

```
"name": "esp8266"
"architecture": "esp8266"
"version": "2.4.1"
```

```
board: {
  name: "NodeMCU 1.0 (ESP-12E Module)"
  id:   "nodemcuv2"
}
```


### Tutorials

#### Print on serial

```c
void setup() {
  Serial.begin(115200);
}

void loop() {
  Serial.println("Loop");
  delay(500);
}
```


#### Blink internal LED:

```c
#define LED_BUILTIN 2

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  digitalWrite(LED_BUILTIN, LOW);
  delay(500);
  digitalWrite(LED_BUILTIN, HIGH);
  delay(1000);
}
```

