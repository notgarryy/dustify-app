# Dustify [W.I.P.]
Dustify is a portable ambient particulate analyzer designed to monitor air quality, specifically measuring PM2.5 and PM10 levels. It uses an ESP32-S3 microcontroller to collect sensor data and send it to a smartphone via Bluetooth. The application provides real-time air quality monitoring and allows users to manage connected devices efficiently.

## Features
- Real-time Air Quality Monitoring: Measures PM2.5 and PM10 levels using the Sensirion SPS30 sensor.
- Bluetooth Connectivity: Connects to the Dustify device using Bluetooth.
- Device Management: Add, remove, and filter connected devices.
- User Interface: Displays connected devices in a ListTile format with options to delete or add a new device.
- Persistent Storage: Saves connected device details using SharedPreferences.

## Dependencies
- flutter_blue_plus: "1.35.3"<br>
- firebase_core: "3.12.1"<br>
- firebase_auth: "5.5.1"<br>
- firebase_analytics: "11.4.4"<br>
- cloud_firestore: "5.6.5"<br>
- get_it: "8.0.3"<br>
- shared_preferences: "2.5.3"<br>
- fl_chart: "0.70.2"

## Update History
### v0.0.1 - April 4th, 2025 
- BLE scanner
- BLE connection to ESP32
- Read data from ESP32

### v0.0.2 - April 4th, 2025 
- User Interface

### v0.0.3 - April 5th, 2025 
- Fixed crashing issues
- Fixed BLE connection issues
- Added BLE manager — now the data is available on the home page
- Added a placeholder AQI meter

### v0.0.4 - April 13th, 2025 
- Updated the code to receive string data from the ESP32 device, instead of integer data
- Implemented a parsing feature, to parse the string data into PM2.5 and PM10 data
- Updated the AQI meter threshold parameter

## TODO:
- Graph BLE Data
- Integrate with Firebase

[notgarryy]
