#include "CaptivePortal.h"
#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>
extern "C" {
  #include "user_interface.h"
}


void CaptivePortal::setup() {
  delay(1000);
  Serial.begin(115200);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
  Serial.println();
  Serial.print("Configuring access point... ");

  enableSoftAP();
  delay(500); // Without delay I've seen the IP address blank
  Serial.print("AP IP address: ");
  Serial.println(WiFi.softAPIP());

  /* Setup the DNS server redirecting all the domains to the apIP */
  dnsServer.setErrorReplyCode(DNSReplyCode::NoError);
  dnsServer.start(DNS_PORT, "*", apIP);

  server.on("/", HTTP_GET, [this]() { handleRoot(); });
  server.on("/connect", HTTP_POST, [this]() { handleConnect(); });
  server.on("/disconnect", HTTP_POST, [this]() { handleDisconnect(); });
  server.on("/disable-ap", HTTP_POST, [this]() { handleDisableAP(); });
  server.on("/enable-ap", HTTP_POST, [this]() { handleEnableAP(); });
  server.on("/connecting", HTTP_GET, [this]() { handleConnecting(); });
  server.on("/status", HTTP_GET, [this]() { handleStatus(); });
  server.onNotFound([this]() { handleNotFound(); });

  server.begin(); // Web server start
  Serial.println("HTTP server started");

  // Setup MDNS responder
  if (!MDNS.begin(myHostname.c_str())) {
    Serial.println("Error setting up MDNS responder!");
  } else {
    Serial.println("mDNS responder started");
    // Add service to MDNS-SD
    MDNS.addService("http", "tcp", 80);
  }

  connect = ssid.length() > 0; // Request WLAN connect if there is a SSID
}

void CaptivePortal::enableSoftAP() {
  WiFi.softAPConfig(apIP, apIP, netMsk);
  WiFi.softAP(softAP_ssid, softAP_password);
}

void CaptivePortal::handleDisableAP() {
  logRequest();
  WiFi.softAPdisconnect(true);

  server.sendHeader("Location", "/");
  server.send(303);
}

void CaptivePortal::handleEnableAP() {
  logRequest();
  enableSoftAP();

  server.sendHeader("Location", "/");
  server.send(303);
}

void CaptivePortal::handleRoot() {
  if (preHandle()) {
    return;
  }
  server.send(200, "text/html", resources.rootHtml);
}

void CaptivePortal::handleConnect() {
  logRequest();
  for (uint8_t i = 0; i < server.args(); i++) {
    String argName = server.argName(i);
    String argValue = server.arg(i);
    if (argName == "ssid") {
      Serial.printf("Setting ssid to: '%s'\n", argValue.c_str());
      ssid = argValue;
      lastConnectionStatus = WL_IDLE_STATUS;
    }
    if (argName == "password") {
      Serial.println("Setting wifi password");
      password = argValue;
      lastConnectionStatus = WL_IDLE_STATUS;
    }
  }
  server.sendHeader("Location", "/connecting");
  server.send(303);
}

void CaptivePortal::handleDisconnect() {
  logRequest();
  WiFi.disconnect();
  ssid = "";
  password = "";
  lastConnectionStatus = WL_IDLE_STATUS;

  server.sendHeader("Location", "/");
  server.send(303);
}

void CaptivePortal::handleConnecting() {
  if (preHandle()) {
    return;
  }

  server.send(200, "text/html", resources.connectingHtml);
  connect = true;
}

void CaptivePortal::handleStatus() {
  if (preHandle()) {
    return;
  }
  snprintf(
      buffer,
      sizeof(buffer),
      "{"
        "\"wifi\":{\"ssid\":\"%s\",\"status\":\"%s\",\"lastStatus\":\"%s\",\"localIP\": \"%s\"},"
        "\"softAP\":{\"ssid\": \"%s\", \"enabled\":\"%s\",\"ip\":\"%s\",\"clients\":\"%u\"}"
      "}",
      WiFi.SSID().c_str(),
      getWifiStatus().c_str(),
      getLastWifiStatus().c_str(),
      WiFi.localIP().toString().c_str(),
      softAPSSID().c_str(),
      isAPModeEnabled() ? "true" : "false",
      WiFi.softAPIP().toString().c_str(),
      softAPClientsNumber
  );
  server.send(200, "application/json", buffer);
}

void CaptivePortal::handleNotFound() {
  if (preHandle()) {
    return;
  }
  server.sendHeader("Location", "/");
  server.send(302);
}

void CaptivePortal::logRequest() {
  Serial.print("Request for page: ");
  switch(server.method()) {
    case HTTP_GET:
      Serial.print("GET ");
      break;
    case HTTP_POST:
      Serial.print("POST ");
      break;
    default:
      Serial.print("UNKNOWN ");
      break;
  }
  Serial.println(server.hostHeader() + server.uri());
}

bool CaptivePortal::preHandle() {
  logRequest();
  return domainRedirectIfRequired();
}

const String CaptivePortal::getWifiStatusText(unsigned int connStatus) {
  switch (connStatus) {
    case WL_IDLE_STATUS:
      return "WL_IDLE_STATUS";
    case WL_NO_SSID_AVAIL:
      return "WL_NO_SSID_AVAIL";
    case WL_SCAN_COMPLETED:
      return "WL_SCAN_COMPLETED";
    case WL_CONNECTED:
      return "WL_CONNECTED";
    case WL_CONNECT_FAILED:
      return "WL_CONNECT_FAILED";
    case WL_CONNECTION_LOST:
      return "WL_CONNECTION_LOST";
    case WL_DISCONNECTED:
      return "WL_DISCONNECTED";
    default:
      return "UNKNOWN";
  }
}

String CaptivePortal::getWifiStatus() {
  return getWifiStatusText(status);
}

const String CaptivePortal::getLastWifiStatus() {
  if (lastConnectionStatus == WL_IDLE_STATUS) {
    return "";
  }
  return getWifiStatusText(lastConnectionStatus);
}

/**
 * This is copied from newer version of arduino.esp8266.com, that is not released yet
 */
const String CaptivePortal::softAPSSID() {
  struct softap_config config;
  wifi_softap_get_config(&config);
  char* name = reinterpret_cast<char*>(config.ssid);
  char ssid[sizeof(config.ssid) + 1];
  memcpy(ssid, name, sizeof(config.ssid));
  ssid[sizeof(config.ssid)] = '\0';

  return String(ssid);
}

bool CaptivePortal::isAPModeEnabled() {
  WiFiMode_t currentMode = WiFi.getMode();
  return ((currentMode & WIFI_AP) != 0);
}

bool CaptivePortal::domainRedirectIfRequired() {
  if (softAPClientsNumber > 0 && !isWifiConnected()) {
    String host = server.hostHeader();
    String cUri = server.uri();
    const static String correctHost = myHostname + ".local";
    if (host == correctHost) {
      return false;
    }

    String location = "http://" + myHostname + ".local" + cUri;
    server.sendHeader("Location", location);
    server.send(302);
    return true;
  }
  return false;
}

bool CaptivePortal::isWifiConnected() {
  return status == WL_CONNECTED;
}

void CaptivePortal::handle() {
  updateState();
  // Do work:
  //DNS
  dnsServer.processNextRequest();
  //HTTP
  server.handleClient();
}

void CaptivePortal::updateState() {
  if (connect) {
    Serial.println("WiFi connect attempt");
    connect = false;
    connectWifi();
    lastConnectTry = millis();
  }
  {
    unsigned int s = WiFi.status();
    updateLastWifiStatus(s);
    if (s == WL_IDLE_STATUS && millis() > (lastConnectTry + 60000)) {
      /* If WLAN disconnected and idle try to connect */
      /* Don't set retry time too low as retry interfere the softAP operation */
      connect = true;
    }
    if (status != s) { // WLAN status change
      Serial.print("WiFi status changed to: ");
      printWifiStatus(s);
      status = s;
      if (s == WL_CONNECTED) {
        /* Just connected to WLAN */
        Serial.println("");
        Serial.print("Connected to ");
        Serial.println(WiFi.SSID());
        Serial.print("IP address: ");
        Serial.println(WiFi.localIP());

        // TODO: Setup MDNS responder
      } else if (s == WL_NO_SSID_AVAIL) {
        WiFi.disconnect();
      }
    }
  }

  unsigned int currentSoftAPClients = WiFi.softAPgetStationNum();
  if (currentSoftAPClients != softAPClientsNumber) {
    if (currentSoftAPClients > softAPClientsNumber) {
      Serial.printf("New client connected to soft-AP. Current clients number: %d\n", currentSoftAPClients);
    } else {
      Serial.printf("Client disconnected from soft-AP. Current clients number: %d\n", currentSoftAPClients);
    }
    softAPClientsNumber = currentSoftAPClients;
  }
}

void CaptivePortal::connectWifi() {
  if (ssid.length() == 0) {
    Serial.println("SSID not provided, skipping connect...");
    return;
  }
  Serial.printf("Connecting to wifi network: '%s'\n", ssid.c_str());
  WiFi.disconnect();
  WiFi.begin(ssid.c_str(), password.c_str());
  uint8_t connStatus = WiFi.waitForConnectResult();
  Serial.print("connection status: ");
  printWifiStatus(connStatus);
}

void CaptivePortal::updateLastWifiStatus(unsigned int connStatus) {
  if (connStatus == WL_IDLE_STATUS) {
    return;
  }
  if (connStatus == WL_SCAN_COMPLETED) {
    return;
  }
  lastConnectionStatus = connStatus;
}

void CaptivePortal::printWifiStatus(unsigned int connStatus) {
  Serial.println(getWifiStatusText(connStatus));
}
