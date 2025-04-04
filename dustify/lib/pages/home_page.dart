import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ScanResult> scanResultList = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];
  String receivedData = "No data";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter BLE Scan")),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: scanResultList.length,
              itemBuilder: (context, index) {
                return listItem(scanResultList[index]);
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider();
              },
            ),
          ),
          if (connectedDevice != null) // Show data section when connected
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black12,
              child: Column(
                children: [
                  Text(
                    "Connected to: ${connectedDevice?.platformName}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Received Data: $receivedData",
                    style: const TextStyle(fontSize: 18, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: disconnect,
                    child: const Text("Disconnect"),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleState,
        child: Icon(isScanning ? Icons.stop : Icons.search),
      ),
    );
  }

  void toggleState() {
    isScanning = !isScanning;

    if (isScanning) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      scan();
    } else {
      FlutterBluePlus.stopScan();
    }
    setState(() {});
  }

  void scan() async {
    if (isScanning) {
      FlutterBluePlus.scanResults.listen((results) {
        scanResultList = results;
        setState(() {});
      });
    }
  }

  Future<void> onTap(ScanResult r) async {
    try {
      await r.device.connect(timeout: const Duration(seconds: 10));
      setState(() {
        connectedDevice = r.device;
      });

      // Discover services
      List<BluetoothService> discoveredServices =
          await r.device.discoverServices();
      setState(() {
        services = discoveredServices;
      });

      // Find readable characteristic
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            characteristic.setNotifyValue(true);
            characteristic.lastValueStream.listen((value) {
              setState(() {
                if (value.isNotEmpty) {
                  // Convert bytes to hex string for debugging
                  String hexData = value
                      .map((e) => e.toRadixString(16).padLeft(2, '0'))
                      .join(' ');

                  // Convert hex bytes to integer (assume Little-Endian)
                  int intValue = bytesToInt(value, endian: Endian.little);

                  receivedData = "$hexData → Counter: $intValue";
                } else {
                  receivedData = "No data";
                }
              });
            });
          }
        }
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected to ${r.device.platformName}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Connection failed: $e")));
    }
  }

  void disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      setState(() {
        connectedDevice = null;
        receivedData = "No data";
      });
    }
  }

  Widget listItem(ScanResult r) {
    return ListTile(
      onTap: () => onTap(r),
      leading: leading(r),
      title: deviceName(r),
      subtitle: deviceMacAddress(r),
      trailing: deviceSignal(r),
    );
  }

  Widget deviceSignal(ScanResult r) {
    return Text(r.rssi.toString());
  }

  Widget deviceMacAddress(ScanResult r) {
    return Text(r.device.remoteId.toString());
  }

  Widget deviceName(ScanResult r) {
    String name =
        r.device.platformName.isNotEmpty
            ? r.device.platformName
            : (r.advertisementData.advName.isNotEmpty
                ? r.advertisementData.advName
                : 'N/A');
    return Text(name);
  }

  Widget leading(ScanResult r) {
    return CircleAvatar(
      backgroundColor:
          connectedDevice?.remoteId == r.device.remoteId
              ? Colors.green
              : Colors.cyan,
      child: const Icon(Icons.bluetooth, color: Colors.white),
    );
  }

  int bytesToInt(List<int> bytes, {Endian endian = Endian.little}) {
    ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    if (bytes.length == 1) {
      return byteData.getUint8(0);
    } else if (bytes.length == 2) {
      return byteData.getUint16(0, endian);
    } else if (bytes.length == 4) {
      return byteData.getUint32(0, endian);
    } else {
      return bytes.fold(
        0,
        (prev, elem) => (prev << 8) + elem,
      ); // Fallback for unknown lengths
    }
  }
}
