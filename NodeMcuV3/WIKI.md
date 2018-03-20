# NodeMcu V3 Wiki

## esp8266

### Vocabulary

* `SPIFFS` - file system used on esp8266 

### Info

### Links

* Spec: https://github.com/esp8266/Arduino/blob/master/doc/
* Utils:
	* Flash config checker: https://github.com/esp8266/Arduino/blob/master/libraries/esp8266/examples/CheckFlashConfig/CheckFlashConfig.ino

## esp8266 platform on Arduino IDE

### Macros

* `LED_BUILTIN`
	* Not working on NodeMcu V3 (or ESP8266-12E/F in general)

	  For NodeMcu V3 define:

	  ```c
	  #define LED_BUILTIN 2
	  ```

### Sources

Sources for API are defined in: https://github.com/esp8266/Arduino/blob/master/cores/esp8266/ 

For example signature of function `digitalWrite` is here: https://github.com/esp8266/Arduino/blob/master/cores/esp8266/core_esp8266_wiring_digital.c


## Arduino

* preferences and packages localization: `~/.arduino15`

## NodeMcu V3 with Arduino IDE

### Config (based on my unit)

* Flash size: 4M (1M SPIFFS) //(3M SPIFFS also works)
* lwIP Variant: v2 Lower Memory (TODO: verify)
* CPU Frequency: 80 MHz
* Upload Speed: 115200

### Board

"name": "esp8266"
"architecture": "esp8266"
"version": "2.4.1"
board: "NodeMCU 1.0 (ESP-12E Module)"


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

