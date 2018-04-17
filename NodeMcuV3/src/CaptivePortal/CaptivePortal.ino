#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>
#include <DNSServer.h>
#include <ESP8266mDNS.h>
#include <EEPROM.h>

/* Set these to your desired softAP credentials. They are not configurable at runtime */
const char *softAP_ssid = "ESP_NODE_MCU";
const char *softAP_password = "cm52gn3k";

/* Don't set this wifi credentials. They are configurated at runtime and stored on EEPROM */
String ssid = "";
String password = "";

String myHostname = "esp8266";

// DNS server
const byte DNS_PORT = 53;
DNSServer dnsServer;

// Web server
ESP8266WebServer server(80);

/* Soft AP network parameters */
IPAddress apIP(192, 168, 1, 1);
IPAddress netMsk(255, 255, 255, 0);

/** Should I connect to WLAN asap? */
boolean connect;

/** Last time I tried to connect to WLAN */
unsigned long lastConnectTry = 0;

/** Current WLAN status */
unsigned int status = WL_IDLE_STATUS;

unsigned int softAPClientsNumber = 0;

void logRequest() {
  Serial.print("Request for page: ");
  switch(server.method()) {
    case HTTP_GET:
      Serial.print("GET ");
      break;
    case HTTP_POST:
      Serial.print("POST ");
      break;
    default:
      Serial.print("UNKNOWNK ");
      break;
  }
  Serial.println(server.uri());
}

void handleConnect() {
  logRequest();
  for (uint8_t i = 0; i < server.args(); i++) {
    String argName = server.argName(i);
    String argValue = server.arg(i);
    if (argName == "ssid") {
      Serial.printf("Setting ssid to: '%s'\n", argValue.c_str());
      ssid = argValue;
    }
    if (argName == "password") {
      Serial.println("Setting wifi password");
      password = argValue;
    }
  }
  server.sendHeader("Location", "/connecting");
  server.send(303);
  return;
}

String getPage(String content) {
  const static String header = ""
    "<!DOCTYPE html>"
    "<html lang=\"en\">"
    "<head>"
      "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />"
      "<meta charset=\"utf-8\">"
      "<title>ESP8266 Portal</title>"
      "<style>"
        "input {"
          "display: block;"
        "}"
        ".data-ssid {"
          "font-weight: bold;"
        "}"
        ".centered {"
          "text-align: center;"
        "}"
      "</style>"
    "</head>"
    "<body>";
  const static String footer = ""
    "<hr />"
    "<p class=\"centered\"><a href=\"/\">Main page</a></p>"
    "</body>"
    "</html>";
    
  return header + content + footer;
}

void handleConnecting() {
  logRequest();
  const static String content = ""
    "<h1 id=\"header-status\">Loading...</h1>"
    "<p>SSID: <span class=\"data-ssid\"></span></p>"
    "<p id=\"counter-line\"><span id=\"counter\"></span> seconds...</p>"
    "<p>Connection status: <span id=\"wifi-status\"></span></p>"
    "<p id=\"connection-success\" style=\"display: none\">"
      "Device successfully connected to network <span class=\"data-ssid\"></span>."
      "Temporary network will shutdown any second soon! Disconnect from it and connect to <span class=\"data-ssid\"></span> network."
    "<p id=\"connection-failed\" style=\"display: none\">"
      "Timed out waiting for connection!"
    "</p>"
    "</p>"
    "<script>"
      "var remainingSeconds = 60;"
      "var wifiStatus = undefined;"
      "var ssid = undefined;"
      "var timeout = false;"
      "var lastNotIdleConnectionStatus = null;"
      "var fetchStatus = function() {"
        "return fetch('/status', {"
          "method: 'get'"
        "})"
            ".then(function(response) {"
              "return response.json();"
            "})"
            ".catch(function(err) {"
              "console.log(err);"
            "});"
      "};"
      "var fetchStatusLoop = function() {"
        "fetchStatus()"
            ".then(function (status) {"
              "this.wifiStatus = status.wifi.status;"
              "ssid = status.wifi.ssid;"
              "document.getElementById('wifi-status').innerText = getStatusText();"
              "[].forEach.call(document.getElementsByClassName('data-ssid'), function(el) { el.innerText = ssid; });"
              "if (this.wifiStatus !== 'WL_CONNECTED' && !timeout) {"
                "setTimeout(fetchStatusLoop, 2000);"
              "}"
            "});"
      "};"
      "var connectionFailed = function () {"
        "document.getElementById('connection-failed').style.display = null;"
        "document.getElementById('header-status').innerText = \"Connection failed\";"
        "timeout = true;"
      "};"
      "var connectionSuccess = function() {"
        "document.getElementById('connection-success').style.display = null;"
        "document.getElementById('counter-line').style.display = 'none';"
        "document.getElementById('header-status').innerText = \"Connected\""
      "};"
      "var connectionIdle = function () {"
        "document.getElementById('header-status').innerText = \"Waiting for connection...\""
      "};"
      "var getStatusText = function() {"
          "var status = this.wifiStatus;"
          "if (lastNotIdleConnectionStatus && this.wifiStatus === 'WL_IDLE_STATUS') {"
              "status += \" (\" + lastNotIdleConnectionStatus + \")\""
          "}"
          "return status;"
      "};"
      "var tickCounter = function() {"
        "if (remainingSeconds < 0) {"
          "connectionFailed();"
          "clearInterval(counterTicker);"
          "return;"
        "}"
        "setCounter(remainingSeconds--);"
        "if (this.wifiStatus === 'WL_CONNECTED') {"
          "connectionSuccess();"
          "clearInterval(counterTicker);"
        "} else if (this.wifiStatus === 'WL_IDLE_STATUS') {"
          "connectionIdle();"
        "}"
        "if (this.wifiStatus && this.wifiStatus !== 'WL_IDLE_STATUS') {"
            "lastNotIdleConnectionStatus = this.wifiStatus;"
        "}"
      "};"
      "var setCounter = function(val) {"
        "document.getElementById('counter').innerText = val;"
      "};"
      "var counterTicker = setInterval(tickCounter, 1000);"
      "tickCounter();"
      "fetchStatusLoop();"
    "</script>";
  server.send(200, "text/html", getPage(content));  
  connect = true;
}

void handleStatus() {
  char buffer[200];
  snprintf(buffer, sizeof(buffer), "{\"wifi\":{\"ssid\":\"%s\",\"status\":\"%s\"}}", ssid.c_str(), getWifiStatus().c_str());
  server.send(200, "application/json", buffer);
}

void handleRoot() {
  logRequest();
  const static String content = ""
    "<h1>Welcome!</h1>"
    "<h2>WiFi setup</h2>"
    "<form action=\"/connect\" method=\"post\">"
      "<label for=\"input_ssid\">SSID: </label>"
      "<input name=\"ssid\" type=\"text\" id=\"input_ssid\" required />"
      "<label for=\"input_password\">Password: </label>"
      "<input name=\"password\" type=\"password\" id=\"input_password\" />"
      "<input type=\"submit\" value=\"Connect\" />"
    "</form>";
  server.send(200, "text/html", getPage(content));
}

void handleNotFound() {
  server.sendHeader("Location", "/");
  server.send(302);
}

String getWifiStatus() {
  unsigned int connStatus = WiFi.status();
  return getWifiStatusText(connStatus);
}

String getWifiStatusText(unsigned int connStatus) {
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
  }
}

void printWifiStatus(unsigned int connStatus) {
  Serial.println(getWifiStatusText(connStatus));
}

void connectWifi() {
  if (ssid.length() == 0) {
    Serial.println("SSID not provided, skipping connect...");
    return;
  }
  Serial.printf("Connecting to wifi network: '%s'\n", ssid.c_str());
  WiFi.disconnect();
  WiFi.begin(ssid.c_str(), password.c_str());
  int connStatus = WiFi.waitForConnectResult();
  Serial.print("connection status: ");
  printWifiStatus(connStatus);
}



void setup() {
  delay(1000);
  Serial.begin(115200);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
  Serial.println();
  Serial.print("Configuring access point... ");

  WiFi.softAPConfig(apIP, apIP, netMsk);
  WiFi.softAP(softAP_ssid, softAP_password);
  delay(500); // Without delay I've seen the IP address blank
  Serial.print("AP IP address: ");
  Serial.println(WiFi.softAPIP());

  /* Setup the DNS server redirecting all the domains to the apIP */
  dnsServer.setErrorReplyCode(DNSReplyCode::NoError);
  dnsServer.start(DNS_PORT, "*", apIP);

  server.on("/", HTTP_GET, handleRoot);
  server.on("/connect", HTTP_POST, handleConnect);
  server.on("/connecting", HTTP_GET, handleConnecting);
  server.on("/status", HTTP_GET, handleStatus);
  server.onNotFound(handleNotFound);

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

  //loadCredentials(); // TODO: Load WLAN credentials from network
  
  connect = ssid.length() > 0; // Request WLAN connect if there is a SSID
}

void loop() {
  if (connect) {
    Serial.println("WiFi connect attempt");
    connect = false;
    connectWifi();
    lastConnectTry = millis();
  }
  {
    unsigned int s = WiFi.status();
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
        Serial.println(ssid);
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
  // Do work:
  //DNS
  dnsServer.processNextRequest();
  //HTTP
  server.handleClient();
}


