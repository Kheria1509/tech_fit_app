#include &lt;Wire.h&gt;
#include &lt;ESP8266WiFi.h&gt;
#include &lt;FirebaseESP8266.h&gt;
#include &quot;MAX30100_PulseOximeter.h&quot;
// Firebase credentials
#define FIREBASE_HOST &quot;smart-treadmill-eeade-default-rtdb.firebaseio.com&quot;
#define FIREBASE_AUTH &quot;RIX5QlgBvZMTrRc76Ih57vgdnGsH03UOnvan8h28&quot;
// Wi‑Fi credentials
const char* ssid = &quot;113&quot;;
const char* password = &quot;12345678&quot;;
// Button pin &amp; debounce parameters
#define BUTTON_PIN 12
#define DEBOUNCE_DELAY 50 // milliseconds
// Firebase and sensor objects
FirebaseData firebaseData;
PulseOximeter pox;
uint32_t tsLastReport = 0;
#define REPORTING_PERIOD_MS 1000
// Debounce state
int lastButtonState = HIGH;
int buttonState = HIGH;
unsigned long lastDebounceTime = 0;
int speed = 0;
// Beat detection callback
void onBeatDetected() {
Serial.println(&quot;Beat detected!&quot;);
}
void setup() {
Serial.begin(115200);
pinMode(A0, INPUT);
pinMode(BUTTON_PIN, INPUT_PULLUP);
delay(1000);
Serial.print(&quot;Connecting to WiFi...&quot;);
WiFi.begin(ssid, password);
while (WiFi.status() != WL_CONNECTED) {
delay(500);
Serial.print(&quot;.&quot;);
}
Serial.println(&quot; connected.&quot;);
Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
Firebase.reconnectWiFi(true);
Serial.print(&quot;Initializing Pulse Oximeter...&quot;);
if (!pox.begin()) {
Serial.println(&quot;FAIL. Check wiring!&quot;);
while (1);

}
Serial.println(&quot;OK.&quot;);
pox.setOnBeatDetectedCallback(onBeatDetected);
}
void loop() {
// Debounce button
int reading = digitalRead(BUTTON_PIN);
if (reading != lastButtonState) {
lastDebounceTime = millis();
}
if ((millis() - lastDebounceTime) &gt; DEBOUNCE_DELAY) {
if (reading != buttonState) {
buttonState = reading;
speed = (buttonState == LOW) ? 0 : 1;
}
}
lastButtonState = reading;
pox.update();
if (millis() - tsLastReport &gt; REPORTING_PERIOD_MS) {
float hr = pox.getHeartRate();
float spo2 = pox.getSpO2();
int vibration = analogRead(A0);
if (hr &gt; 0 &amp;&amp; hr &lt; 200 &amp;&amp; spo2 &gt; 50 &amp;&amp; spo2 &lt;= 100) {
Serial.printf(&quot;HR: %.1f bpm | SpO2: %.1f%% | Vibration: %d | Speed: %d\n&quot;, hr, spo2,
vibration, speed);
FirebaseJson json;
json.set(&quot;HeartRate&quot;, hr);
json.set(&quot;SpO2&quot;, spo2);
json.set(&quot;vibration&quot;, vibration);
json.set(&quot;speed&quot;, speed);
// Using timestamp path to prevent overwriting
String path = &quot;/health_data/&quot; + String(firebaseData.now());
if (Firebase.set(firebaseData, path, json)) {
Serial.println(&quot;✅ Sent to Firebase&quot;);
} else {
Serial.print(&quot;❌ Firebase error: &quot;);
Serial.println(firebaseData.errorReason());
}
} else {
Serial.println(&quot;⚠️ Invalid sensor data&quot;);
}
tsLastReport = millis();
}
}