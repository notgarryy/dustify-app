import 'dart:async';
import 'dart:convert';
import 'package:dustify/services/firebase_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final StreamController<Map<String, double>> _parsedDataController =
      StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get parsedDataStream =>
      _parsedDataController.stream;

  Map<String, double>? _lastKnownData;
  Map<String, double>? get lastKnownData => _lastKnownData;

  bool _isConnectingOrConnected = false;

  List<double> last60PM25 = [];
  List<double> last60PM10 = [];

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnectingOrConnected) {
      debugPrint("Already connecting or connected. Skipping...");
      return;
    }

    _isConnectingOrConnected = true;

    try {
      // Check if the device is already connected
      var connectedDevices = await FlutterBluePlus.connectedDevices;
      if (connectedDevices.isNotEmpty) {
        for (var d in connectedDevices) {
          if (d.remoteId == device.remoteId) {
            debugPrint('Already connected to device: ${device.remoteId}');
            connectedDevice = d;
            _isConnectingOrConnected = false;
            return;
          }
        }
      }

      await device.connect(timeout: Duration(seconds: 10));
      connectedDevice = device;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('connected_device_id', device.remoteId.str);
      await prefs.setString('connected_device_name', device.platformName);

      final services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            notifyCharacteristic = characteristic;
            await characteristic.setNotifyValue(true);

            characteristic.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                String data = utf8.decode(value);
                final now = DateTime.now();
                final time =
                    "${now.hour.toString().padLeft(2, '0')}:"
                    "${now.minute.toString().padLeft(2, '0')}:"
                    "${now.second.toString().padLeft(2, '0')}."
                    "${(now.millisecond).toString().padLeft(3, '0')}";
                debugPrint("$time - Received BLE data: $data");
                _parseSensorData(data);
              }
            });
            break;
          }
        }
      }

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          connectedDevice = null;
          _isConnectingOrConnected = false;
          _dataController.add(-1);
        }
      });
    } catch (e) {
      debugPrint("Connection failed: $e");
    }

    _isConnectingOrConnected = false;
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
      _isConnectingOrConnected = false;
      _dataController.add(-1);
    }
  }

  void _parseSensorData(String rawData) async {
    try {
      List<String> parts = rawData.split('#');
      if (parts.length == 2) {
        double pm25 = double.parse(parts[0]);
        double pm10 = double.parse(parts[1]);

        FirebaseService().sendPMData(pm25: pm25, pm10: pm10);

        Map<String, double> data = {'PM2.5': pm25, 'PM10': pm10};
        _lastKnownData = data;
        _parsedDataController.add(data);

        // Save to internal list
        last60PM25.add(pm25);
        last60PM10.add(pm10);

        if (last60PM25.length > 60) last60PM25.removeAt(0);
        if (last60PM10.length > 60) last60PM10.removeAt(0);

        // Persist it
        await saveRecentData();
      } else {
        debugPrint("Invalid data format: $rawData");
      }
    } catch (e) {
      debugPrint("Failed to parse sensor data: $e");
    }
  }

  Future<void> saveRecentData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'recent_pm25',
      last60PM25.map((e) => e.toStringAsFixed(2)).toList(),
    );
    prefs.setStringList(
      'recent_pm10',
      last60PM10.map((e) => e.toStringAsFixed(2)).toList(),
    );
  }

  Future<void> loadRecentData() async {
    final prefs = await SharedPreferences.getInstance();
    final pm25Str = prefs.getStringList('recent_pm25') ?? [];
    final pm10Str = prefs.getStringList('recent_pm10') ?? [];

    last60PM25 = pm25Str.map((e) => double.tryParse(e) ?? 0.0).toList();
    last60PM10 = pm10Str.map((e) => double.tryParse(e) ?? 0.0).toList();
  }

  Future<void> tryReconnectFromPreferences() async {
    if (_isConnectingOrConnected || connectedDevice != null) {
      debugPrint("Skipping reconnect — already in process or connected.");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString('connected_device_id');

    if (savedId == null) return;

    List<BluetoothDevice> bondedDevices = await FlutterBluePlus.bondedDevices;

    for (var device in bondedDevices) {
      if (device.remoteId.str == savedId) {
        debugPrint("Found bonded device: ${device.remoteId}");
        await connectToDevice(device);
        break;
      }
    }
  }
}
