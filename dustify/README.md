# Dustify [W.I.P.]
Dustify is a portable ambient particulate analyzer designed to monitor air quality, specifically measuring PM2.5 and PM10 levels. It uses an ESP32-S3 microcontroller to collect sensor data and send it to a smartphone via Bluetooth. The application provides real-time air quality monitoring and allows users to manage connected devices efficiently.

## Features
- Real-time Air Quality Monitoring: Measures PM2.5 and PM10 levels using the Sensirion SPS30 sensor.
- Bluetooth Connectivity: Connects to the Dustify device using Bluetooth.
- Device Management: Add, remove, and filter connected devices.
- User Interface: Displays connected devices in a ListTile format with options to delete or add a new device.
- Persistent Storage: Saves connected device details using SharedPreferences.

## Dependencies
- flutter_blue_plus: "1.35.3"
- firebase_core: "3.12.1"
- firebase_auth: "5.5.1"
- firebase_analytics: "11.4.4"
- cloud_firestore: "5.6.5"
- get_it: "8.0.3"
- shared_preferences: "2.5.3"
- fl_chart: "0.70.2"
- syncfusion_flutter_gauges: "29.1.38"
- flutter_native_splash: "2.4.6"

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
- Added a placeholder AQI gauge

### v0.0.4 - April 12th, 2025 
- Updated the code to receive string data from the ESP32 device, instead of integer data
- Implemented a parsing feature, to parse the string data into PM2.5 and PM10 data
- Updated the AQI meter threshold parameter

### v0.0.5 - April 13th, 2025
- Firebase integrated
- Bottom navigation can navigate between the main page and the profile page

### v0.0.6 - April 14th, 2025
- Added splash screen
- Updated app icon
- Updated app name

### v0.0.7 - April 15th, 2025
- Fixed splash screen resolution
- Improved BLE connection, it now requires pairing with device first, then only it can receive data from the device
- Remove BLE scanner
- Able to receive data when application is running in the background
- When a past paired device is detected, will automatically reconnect with device upon opening the application
- Added line graph that shows data change in an hour
- Updated AQI gauge, pointer now shows between the range in the gauge

### v0.0.8 - April 16th, 2025
- Added profile page
- Added login, sign up, and logout feature - complete with Firebase integration

## TODO:
- Send data to Firebase
- History page

[notgarryy]
