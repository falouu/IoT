#ifndef NODEMCUV3_CAPTIVEPORTAL_RESOURCES_H
#define NODEMCUV3_CAPTIVEPORTAL_RESOURCES_H

#endif //NODEMCUV3_CAPTIVEPORTAL_RESOURCES_H

class Resources {
public:
  const String fetchStatusJs {
    "var error = function(message, err) {"
      "console.log(message, err);"
      "var container = document.getElementById('error');"
      "container.innerText = message + \". Caused by: \" + err;"
      "container.style.display = null"
    "};"
    "var fetchStatus = function() {"
      "return fetch('/status', {"
        "method: 'get'"
      "})"
          ".then(function(response) {"
            "if(!response.ok) {"
              "throw new Error('Invalid status code: ' + response.status)"
            "}"
            "return response.json();"
          "})"
          ".catch(function(err) {"
            "console.log(err);"
            "error(\"Fetch template error!\", err);"
            "throw err;"
          "});"
    "};"
  };
};