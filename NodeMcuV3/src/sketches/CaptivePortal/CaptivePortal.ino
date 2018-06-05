#include <Arduino.h>

#include <CaptivePortal.h>

CaptivePortal captivePortal;

void setup() {
  captivePortal.setup();
}

void loop() {
  captivePortal.handle();
}


