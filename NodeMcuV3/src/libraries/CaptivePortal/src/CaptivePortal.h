#ifndef NODEMCUV3_CAPTIVEPORTAL_H
#define NODEMCUV3_CAPTIVEPORTAL_H

#include <Arduino.h>

class CaptivePortal {
public:
  void setup();
  void handle();

private:
  void enableSoftAP();
  void handleDisableAP();
  void handleEnableAP();
  const String softAPSSID();
  bool isAPModeEnabled();
};

#endif //NODEMCUV3_CAPTIVEPORTAL_H