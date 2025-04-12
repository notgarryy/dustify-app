import 'package:dustify/services/ble_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FindDevices extends StatefulWidget {
  const FindDevices({super.key});

  @override
  State<FindDevices> createState() => _FindDevicesState();
}

class _FindDevicesState extends State<FindDevices> {
  List<ScanResult> scanResultList = [];
  bool isScanning = false;
  bool isLoading = false;
  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];
  Map<String, double> parsedData =
      {}; // For storing parsed PM2.5 and PM10 values
  String? connectedDeviceId;

  @override
  void initState() {
    super.initState();
    _loadConnectedDevice();
  }

  Future<void> _loadConnectedDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      connectedDeviceId = prefs.getString('connected_device_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    double? _devHeight = MediaQuery.of(context).size.height;
    double? _devWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Color.fromRGBO(34, 31, 31, 1),
      appBar: AppBar(
        title: Text(
          "Find Devices",
          style: TextStyle(fontFamily: 'BungeeSpice', fontSize: 35),
        ),
        backgroundColor: Color.fromRGBO(29, 28, 28, 1),
        centerTitle: true,
        toolbarHeight: _devHeight * 0.08,
        leading: GestureDetector(
          onTap: () {
            FlutterBluePlus.stopScan();
            setState(() {});
            Navigator.popAndPushNamed(context, 'home');
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
                Container(
                  margin: EdgeInsets.symmetric(vertical: _devHeight * 0.07),
                  width: _devWidth * 0.8,
                  child: MaterialButton(
                    onPressed: toggleState,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    height: _devHeight * 0.05,
                    color: Color.fromRGBO(255, 116, 46, 1),
                    child: Text(
                      isScanning ? "Stop Scan" : "Find Device",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void toggleState() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        connectedDevice = null;
        parsedData = {}; // Reset parsed data
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('connected_device_id');
      await prefs.remove('connected_device_name');
      setState(() {
        connectedDeviceId = null;
      });
    }

    isScanning = !isScanning;
    if (isScanning) {
      setState(() {
        isLoading = true;
      });

      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      scan();
    } else {
      FlutterBluePlus.stopScan();
      setState(() {
        isLoading = false;
      });
    }

    setState(() {});
  }

  void scan() async {
    if (isScanning) {
      final startTime = DateTime.now();

      FlutterBluePlus.scanResults.listen((results) async {
        if (!mounted) return;

        List<ScanResult> filtered =
            results.where((result) {
              String name =
                  result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : (result.advertisementData.advName.isNotEmpty
                          ? result.advertisementData.advName
                          : 'N/A');
              return name != 'N/A';
            }).toList();

        final durationElapsed = DateTime.now().difference(startTime);
        final delay = Duration(seconds: 1) - durationElapsed;

        if (delay.inMilliseconds > 0) {
          await Future.delayed(delay);
        }

        if (!mounted) return;
        setState(() {
          scanResultList = filtered;
          isLoading = false;
        });
      });
    }
  }

  Future<void> onTap(ScanResult r) async {
    try {
      await BLEManager().connectToDevice(r.device);
      await saveConnectedDevice(r.device);
      await r.device.connect(timeout: const Duration(seconds: 10));
      FlutterBluePlus.stopScan();

      setState(() {
        isScanning = false;
        connectedDevice = r.device;
      });

      List<BluetoothService> discoveredServices =
          await r.device.discoverServices();
      setState(() {
        services = discoveredServices;
      });

      await saveConnectedDevice(r.device);

      if (mounted) {
        Navigator.pushReplacementNamed(context, 'home');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Connection failed: $e")));
    }
  }

  Future<void> saveConnectedDevice(BluetoothDevice device) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('connected_device_id', device.remoteId.toString());
    await prefs.setString('connected_device_name', device.platformName);
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan(); // 🧹 Important cleanup
    super.dispose();
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
    return Text(
      name,
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),
    );
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
}
