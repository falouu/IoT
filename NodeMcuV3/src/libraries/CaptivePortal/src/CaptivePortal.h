#ifndef NODEMCUV3_CAPTIVEPORTAL_H
#define NODEMCUV3_CAPTIVEPORTAL_H

#include <Arduino.h>
#include <ESP8266WebServer.h>

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

  //// CONSTANTS /////////////////
  // DNS server
  const byte DNS_PORT = 53;
  /* Soft AP network parameters */
  const IPAddress apIP { IPAddress(192, 168, 1, 1) };
  const IPAddress netMsk { IPAddress(255, 255, 255, 0) };
  const String myHostname = "esp8266";

  /* Set these to your desired softAP credentials. They are not configurable at runtime */
  const char *softAP_ssid = "ESP_NODE_MCU";
  const char *softAP_password = "cm52gn3k";

  //// END OF CONSTANTS /////////////////
};

#endif //NODEMCUV3_CAPTIVEPORTAL_H