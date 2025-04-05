import 'dart:async';
import 'dart:typed_data';
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
              int data = _bytesToInt(value, endian: Endian.little);
              _dataController.add(data);
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

  int _bytesToInt(List<int> bytes, {Endian endian = Endian.little}) {
    ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    if (bytes.length == 1) return byteData.getUint8(0);
    if (bytes.length == 2) return byteData.getUint16(0, endian);
    if (bytes.length == 4) return byteData.getUint32(0, endian);

    return bytes.fold(0, (prev, elem) => (prev << 8) + elem);
  }
}
