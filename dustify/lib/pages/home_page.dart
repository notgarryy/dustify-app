import 'package:dustify/widgets/aqi_meter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:dustify/services/ble_manager.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPage = 0;
  String? connectedDeviceName;
  String? connectedDeviceId;
  int? deviceData;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? notifyCharacteristic;
  StreamSubscription<int>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _loadConnectedDevice();

    _dataSubscription = BLEManager().dataStream.listen((value) {
      if (mounted && value != -1) {
        setState(() {
          deviceData = value;
        });
      }
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
          "Dustify",
          style: TextStyle(fontFamily: 'BungeeSpice', fontSize: 40),
        ),
        backgroundColor: Color.fromRGBO(29, 28, 28, 1),
        centerTitle: true,
        toolbarHeight: _devHeight * 0.08,
      ),
      bottomNavigationBar: _bottomNavBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  connectedDeviceName != null
                      ? _connectedDeviceView()
                      : Center(
                        child: Text(
                          "No connected devices",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
            ),
            if (connectedDeviceName == null)
              Container(
                margin: EdgeInsets.symmetric(vertical: _devHeight * 0.07),
                width: _devWidth * 0.8,
                child: MaterialButton(
                  onPressed: () {
                    Navigator.popAndPushNamed(context, 'find_device');
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  height: _devHeight * 0.05,
                  color: Color.fromRGBO(255, 116, 46, 1),
                  child: Text(
                    "+ Add a new device",
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
      ),
    );
  }

  Future<void> _loadConnectedDevice() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? deviceName = prefs.getString('connected_device_name');
      String? deviceId = prefs.getString('connected_device_id');

      setState(() {
        connectedDeviceName = deviceName; // KEEP null if not available
        connectedDeviceId = deviceId ?? ""; // fallback is OK here
      });
    } catch (e, stack) {
      debugPrint("Error in _loadConnectedDevice: $e");
      debugPrint("Stack trace: $stack");
    }
  }

  Widget _connectedDeviceView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bluetooth, color: Colors.cyan),
              SizedBox(width: 10),
              Text(
                connectedDeviceName!,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.delete_forever_rounded, color: Colors.red),
                onPressed: _clearConnectedDevice,
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            "Device ID: ${connectedDeviceId!.isNotEmpty ? connectedDeviceId! : "No ID available"}",
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 10),
          deviceData != null
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Live Data: ${deviceData} µg/m³",
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  AQIMeter(value: deviceData!),
                ],
              )
              : Text(
                "Live Data: Waiting...",
                style: TextStyle(color: Colors.orangeAccent, fontSize: 16),
              ),
        ],
      ),
    );
  }

  Future<void> _clearConnectedDevice() async {
    try {
      // Disconnect from BLE device
      await BLEManager().disconnect();

      // Clear SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('connected_device_name');
      await prefs.remove('connected_device_id');

      // Clear local state
      if (mounted) {
        setState(() {
          connectedDeviceName = null;
          connectedDeviceId = null;
          deviceData = null;
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Device disconnected")));
    } catch (e, stack) {
      debugPrint("Error in _clearConnectedDevice: $e");
      debugPrint("Stack trace: $stack");
    }
  }

  Widget _bottomNavBar() {
    return BottomNavigationBar(
      elevation: 2,
      backgroundColor: Color.fromRGBO(29, 28, 28, 1),
      currentIndex: _currentPage,
      onTap: (_index) {
        setState(() {
          _currentPage = _index;
        });
      },
      selectedItemColor: Colors.white,
      unselectedItemColor: Color.fromRGBO(133, 133, 133, 0.7),
      items: [
        BottomNavigationBarItem(label: "Home", icon: Icon(Icons.home_filled)),
        BottomNavigationBarItem(
          label: "Profile",
          icon: Icon(Icons.account_box),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}
