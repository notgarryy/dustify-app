import 'package:dustify/widgets/aqi_meter.dart';
import 'package:dustify/widgets/graph.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dustify/services/ble_manager.dart';
import 'dart:async';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  String? connectedDeviceName;
  String? connectedDeviceId;
  Map<String, double>? deviceData;
  StreamSubscription<Map<String, double>>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _loadConnectedDevice();

    BLEManager().tryReconnectFromPreferences();

    final cached = BLEManager().lastKnownData;
    if (cached != null) {
      setState(() {
        deviceData = cached;
      });
    }

    _dataSubscription = BLEManager().parsedDataStream.listen((data) {
      if (mounted) {
        debugPrint("New parsed data received: $data");
        setState(() {
          deviceData = data;
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
        connectedDeviceName = deviceName;
        connectedDeviceId = deviceId ?? "";
      });
    } catch (e, stack) {
      debugPrint("Error in _loadConnectedDevice: $e");
      debugPrint("Stack trace: $stack");
    }
  }

  Widget _connectedDeviceView() {
    return SingleChildScrollView(
      child: Container(
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
                Icon(Icons.bluetooth, color: Colors.cyan, size: 30),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connectedDeviceName!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      "Device ID: ${connectedDeviceId!.isNotEmpty ? connectedDeviceId! : "No ID available"}",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.orangeAccent),
                      tooltip: "Reconnect",
                      onPressed: _refreshConnection,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                      ),
                      tooltip: "Disconnect",
                      onPressed: _clearConnectedDevice,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            deviceData != null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "PM10: ${deviceData!['PM10']} µg/m³",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "${_getAQILevel(deviceData!['PM10'], false)}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AQIMeter(value: deviceData!['PM10']!, isPM2_5: false),
                    LineGraph(isPM2_5: false),
                    SizedBox(height: 30),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "PM2.5 : ${deviceData!['PM2.5']} µg/m³",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "${_getAQILevel(deviceData!['PM2.5'], true)}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AQIMeter(value: deviceData!['PM2.5']!, isPM2_5: true),
                    LineGraph(isPM2_5: true),
                  ],
                )
                : Text(
                  "Live Data: Waiting...",
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 16),
                ),
          ],
        ),
      ),
    );
  }

  String _getAQILevel(double? value, bool isPM2_5) {
    if (isPM2_5) {
      if (value! <= 15.5) return "Very Good";
      if (value <= 55.4) return "Good";
      if (value <= 150.4) return "Fair";
      if (value <= 250.4) return "Poor";
      return "Hazardous";
    } else {
      if (value! <= 50) return "Very Good";
      if (value <= 150) return "Good";
      if (value <= 350) return "Fair";
      if (value <= 420) return "Poor";
      return "Hazardous";
    }
  }

  Future<void> _clearConnectedDevice() async {
    try {
      await BLEManager().disconnect();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('connected_device_name');
      await prefs.remove('connected_device_id');

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

  Future<void> _refreshConnection() async {
    try {
      debugPrint("Refreshing Bluetooth connection...");
      await BLEManager().disconnect();

      if (mounted) {
        setState(() {
          deviceData = null;
        });
      }

      await BLEManager().tryReconnectFromPreferences();
      debugPrint("Reconnection triggered.");
    } catch (e) {
      debugPrint("Error during refresh: $e");
    }
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}
