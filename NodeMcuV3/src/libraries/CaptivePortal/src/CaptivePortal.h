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

  inline String getWifiStatus();
  const String getWifiStatusText(unsigned int connStatus);
  const String getLastWifiStatus();
  inline bool isWifiConnected();
  void connectWifi();
  inline void updateLastWifiStatus(unsigned int connStatus);
  inline void printWifiStatus(unsigned int connStatus);

  void handleRoot();
  void handleConnect();
  void handleDisconnect();
  void handleConnecting();
  void handleStatus();
  void handleNotFound();
  bool domainRedirectIfRequired();

  void logRequest();
  bool preHandle();
  void updateState();
};

#endif //NODEMCUV3_CAPTIVEPORTAL_H