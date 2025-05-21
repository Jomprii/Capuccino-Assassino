#include <WiFi.h>
#include <HTTPClient.h>
#include "EmonLib.h"  // https://github.com/openenergymonitor/EmonLib

#define WIFI_SSID "onin gwapo"
#define WIFI_PASSWORD "12345678"
#define SERVER_URL "https://app-dev-backend.onrender.com/data" 

EnergyMonitor emon;
#define vCalibration 106.8
#define currCalibration 0.52

float kWh = 0;
unsigned long lastMillis = 0;
unsigned long lastSendTime = 0;
const unsigned long sendInterval = 5000; 

void setup() {
  Serial.begin(115200);
  emon.voltage(35, vCalibration, 1.7); 
  emon.current(34, currCalibration);   

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  lastMillis = millis(); 
}

void loop() {
  if (millis() - lastSendTime >= sendInterval) {
    emon.calcVI(20, 2000);
    float voltage = emon.Vrms;
    float current = emon.Irms;
    float power = emon.apparentPower;

    unsigned long now = millis();
    kWh += power * (now - lastMillis) / 3600000000.0;
    lastMillis = now;
    lastSendTime = now;

    Serial.printf("Voltage: %.2f V, Current: %.2f A, Power: %.2f W, kWh: %.4f\n",
                  voltage, current, power, kWh);

    if (WiFi.status() == WL_CONNECTED) {
      HTTPClient http;
      http.begin(SERVER_URL);
      http.addHeader("Content-Type", "application/json");

      String payload = "{";
      payload += "\"voltage\":" + String(voltage, 2) + ",";
      payload += "\"current\":" + String(current, 2) + ",";
      payload += "\"power\":" + String(power, 2) + ",";
      payload += "\"kwh\":" + String(kWh, 4);
      payload += "}";

      int responseCode = http.POST(payload);
      if (responseCode > 0) {
        Serial.printf("POST response code: %d\n", responseCode);
        String response = http.getString();
        Serial.println("Server response: " + response);
      } else {
        Serial.printf("POST failed: %s\n", http.errorToString(responseCode).c_str());
      }

      http.end();
    } else {
      Serial.println("WiFi not connected.");
    }
  }
}