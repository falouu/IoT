#define LED_BUILTIN 2

// Load Wi-Fi library
#include <ESP8266WiFi.h>

const char* ssid     = "REPLACE_WITH_YOUR_SSID";

WiFiServer server(8080);

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  // Open serial communications and wait for port to open:
  Serial.begin(115200);
  while (!Serial) {
    sleep(
    ; // wait for serial port to connect. Needed for native USB port only
  }

  Serial.printf("Connecting to %s", ssid);
}

void loop() {
  digitalWrite(LED_BUILTIN, LOW);
  delay(500);
  digitalWrite(LED_BUILTIN, HIGH);
  delay(1000);
}

// IN PROGRESS
