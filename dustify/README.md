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
### v0.0.1 – April 4, 2025
- Initial BLE scanner implementation.
- Established BLE connection to ESP32.
- Basic data reading from ESP32.

### v0.0.2 – April 4, 2025
- Improved user interface.

### v0.0.3 – April 5, 2025
- Fixed app crashes and BLE connection issues.
- Introduced a BLE manager for centralized data handling.
- Added a placeholder AQI gauge.

### v0.0.4 – April 12, 2025
- Updated ESP32 communication to receive string data (instead of integers).
- Implemented a parser to extract PM2.5 and PM10 values from strings.
- Adjusted AQI gauge thresholds.

### v0.0.5 – April 13, 2025
- Integrated Firebase for backend services.
- Added bottom navigation (Home ↔ Profile).

### v0.0.6 – April 14, 2025
- Added a custom splash screen.
- Updated app icon and name.

### v0.0.7 – April 15, 2025
- Fixed splash screen resolution issues.
- Improved BLE pairing flow (now requires pairing before data exchange).
- Removed standalone BLE scanner (auto-reconnects to paired devices).
- Enabled background data reception.
- Added hourly line graphs for PM2.5/PM10 trends.
- Enhanced AQI gauge with dynamic pointer positioning.

### v0.0.8 – April 16, 2025
- Added profile page with Firebase Auth (login/signup/logout).

### v0.0.9 – April 27, 2025
- Introduced history page with Firestore integration.
- Fixed login bugs.
- Added a 'forgot password' feature.

### v0.0.10 - May 4, 2025
- Added a feature to automatically remove data from Firestore that is over 30 days.
- Added an about section on profile page.
- Added a 'restart connection' feature on the data page.

### v0.1.0 - May 18, 2025
- Bug fixes with BLE connectivity.
- Data page now shows connectivity status.
- Updated Firestore data management.

### TODO LIST:
- User testing.

[notgarryy]
