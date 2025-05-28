import 'dart:async';
import 'dart:convert';
import 'package:dustify/services/firebase_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BLEManager {
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

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

  StreamSubscription<List<int>>? _notificationSubscription;

  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool get isConnected => connectedDevice != null;

  Timer? _autoReconnectScanTimer;
  bool _hasScanListener = false;

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnectingOrConnected) {
      debugPrint("Already connecting or connected. Skipping...");
      return;
    }

    _isConnectingOrConnected = true;

    try {
      var connectedDevices = await FlutterBluePlus.connectedDevices;
      if (connectedDevices.any((d) => d.remoteId == device.remoteId)) {
        debugPrint('Already connected to device: ${device.remoteId}');
        connectedDevice = device;
        _isConnectingOrConnected = false;
        _connectionStatusController.add(true);
        return;
      }

      await device.connect(timeout: Duration(seconds: 10));
      connectedDevice = device;
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('connected_device_id', device.remoteId.str);
      await prefs.setString('connected_device_name', device.platformName);

      final services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            notifyCharacteristic = characteristic;

            // Cancel any existing subscription
            await _notificationSubscription?.cancel();

            // Enable notifications if not already enabled
            if (!characteristic.isNotifying) {
              await characteristic.setNotifyValue(true);
            }

            _notificationSubscription = characteristic.lastValueStream.listen((
              value,
            ) {
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
          debugPrint("Device disconnected: ${device.remoteId}");
          connectedDevice = null;
          _isConnectingOrConnected = false;
          _dataController.add(-1);
          _connectionStatusController.add(false);
        }
      });
    } catch (e) {
      debugPrint("Connection failed: $e");
      connectedDevice = null;
      _connectionStatusController.add(false);
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

      await _notificationSubscription?.cancel();
      _notificationSubscription = null;

      _dataController.add(-1);
      _connectionStatusController.add(false);
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

        last60PM25.add(pm25);
        last60PM10.add(pm10);

        if (last60PM25.length > 60) last60PM25.removeAt(0);
        if (last60PM10.length > 60) last60PM10.removeAt(0);

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

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint("Max reconnect attempts reached.");
      return;
    }

    _reconnectAttempts++;

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

  /// Starts periodic scanning to auto reconnect when known device advertises again
  void startAutoReconnectScan() {
    if (_autoReconnectScanTimer != null && _autoReconnectScanTimer!.isActive)
      return;

    _autoReconnectScanTimer = Timer.periodic(Duration(seconds: 10), (
      timer,
    ) async {
      if (connectedDevice != null || _isConnectingOrConnected) return;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedId = prefs.getString('connected_device_id');
      if (savedId == null) return;

      if (!_hasScanListener) {
        _hasScanListener = true;
        FlutterBluePlus.scanResults.listen((results) async {
          for (ScanResult r in results) {
            if (r.device.remoteId.str == savedId) {
              debugPrint(
                "🔄 Found known device advertising: ${r.device.remoteId}",
              );
              await FlutterBluePlus.stopScan();
              await connectToDevice(r.device);
              break;
            }
          }
        });
      }

      await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    });
  }

  /// Stops the periodic auto reconnect scanning
  void stopAutoReconnectScan() {
    _autoReconnectScanTimer?.cancel();
    _autoReconnectScanTimer = null;
    _hasScanListener = false;
  }
}
