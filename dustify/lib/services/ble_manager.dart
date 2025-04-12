import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEManager {
  // Singleton pattern
  static final BLEManager _instance = BLEManager._internal();
  factory BLEManager() => _instance;
  BLEManager._internal();

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? notifyCharacteristic;

  final StreamController<int> _dataController =
      StreamController<int>.broadcast();
  Stream<int> get dataStream => _dataController.stream;

  // To store the parsed PM2.5 and PM10 values
  final StreamController<Map<String, double>> _parsedDataController =
      StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get parsedDataStream =>
      _parsedDataController.stream;

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(timeout: Duration(seconds: 10));
    connectedDevice = device;

    final services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          notifyCharacteristic = characteristic;
          await characteristic.setNotifyValue(true);

          characteristic.lastValueStream.listen((value) {
            if (value.isNotEmpty) {
              String data = utf8.decode(
                value,
              ); // Decode the bytes into a string
              _parseSensorData(data); // Parse and handle the sensor data
            }
          });
          break;
        }
      }
    }

    // Listen for disconnection
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        connectedDevice = null;
        _dataController.add(-1); // or handle it differently
      }
    });
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
      } catch (e) {
        debugPrint("BLE disconnect error: $e");
      }
      connectedDevice = null;
      notifyCharacteristic = null;
      _dataController.add(-1);
    }
  }

  // Function to parse sensor data string (PM2.5#PM10)
  void _parseSensorData(String rawData) {
    try {
      List<String> parts = rawData.split('#'); // Split based on '#'
      if (parts.length == 2) {
        double pm25 = double.parse(parts[0]); // Parse PM2.5
        double pm10 = double.parse(parts[1]); // Parse PM10

        // Add the parsed data to the controller
        _parsedDataController.add({'PM2.5': pm25, 'PM10': pm10});
      } else {
        debugPrint("Invalid data format: $rawData");
      }
    } catch (e) {
      debugPrint("Failed to parse sensor data: $e");
    }
  }
}
