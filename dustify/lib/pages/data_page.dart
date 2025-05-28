import 'package:dustify/services/firebase_manager.dart';
import 'package:dustify/widgets/aqi_meter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
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
  bool isConnected = false;
  StreamSubscription<Map<String, double>>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    BLEManager().startAutoReconnectScan();
    _loadConnectedDevice();
    BLEManager().tryReconnectFromPreferences();

    final cached = BLEManager().lastKnownData;
    if (cached != null) {
      setState(() {
        deviceData = cached;
        isConnected = true;
        FirebaseService().sendConnectionStatus(true);
      });
    }

    _dataSubscription = BLEManager().parsedDataStream.listen((data) {
      if (mounted) {
        debugPrint("New parsed data received: $data");
        setState(() {
          deviceData = data;
          isConnected = true;
          FirebaseService().sendConnectionStatus(true);
        });
      }
    });
  }

  @override
  void dispose() {
    BLEManager().stopAutoReconnectScan();
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double? _devHeight = MediaQuery.of(context).size.height;
    double? _devWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(34, 31, 31, 1),
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
                  color: const Color.fromRGBO(255, 116, 46, 1),
                  child: const Text(
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
            StreamBuilder<bool>(
              stream: BLEManager().connectionStatusStream,
              initialData: BLEManager().isConnected,
              builder: (context, snapshot) {
                final bool isConnected = snapshot.data ?? false;

                return Row(
                  children: [
                    const Icon(Icons.bluetooth, color: Colors.cyan, size: 30),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connectedDeviceName ?? "Unknown Device",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isConnected
                              ? "Status: Connected"
                              : "Status: Disconnected",
                          style: TextStyle(
                            color:
                                isConnected
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.orangeAccent,
                          ),
                          tooltip: "Reconnect",
                          onPressed: _refreshConnection,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.red,
                          ),
                          tooltip: "Disconnect",
                          onPressed: _clearConnectedDevice,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            deviceData != null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: SfRadialGauge(
                            axes: <RadialAxis>[
                              RadialAxis(
                                minimum: 0,
                                maximum: 300,
                                ranges: <GaugeRange>[
                                  GaugeRange(
                                    startValue: 0,
                                    endValue: 50,
                                    color: Colors.lightGreen,
                                  ),
                                  GaugeRange(
                                    startValue: 50,
                                    endValue: 100,
                                    color: Colors.green,
                                  ),
                                  GaugeRange(
                                    startValue: 100,
                                    endValue: 150,
                                    color: Colors.yellow,
                                  ),
                                  GaugeRange(
                                    startValue: 150,
                                    endValue: 200,
                                    color: Colors.orange,
                                  ),
                                  GaugeRange(
                                    startValue: 200,
                                    endValue: 300,
                                    color: Colors.red,
                                  ),
                                ],
                                pointers: <GaugePointer>[
                                  NeedlePointer(
                                    value:
                                        calculateISPU(
                                          deviceData!['PM10'],
                                          false,
                                        ).toDouble(),
                                    needleColor: Colors.white,
                                    needleEndWidth: 3,
                                    knobStyle: const KnobStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                                annotations: <GaugeAnnotation>[
                                  GaugeAnnotation(
                                    widget: Text(
                                      'ISPU\n${calculateISPU(deviceData!['PM10'], false)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    angle: 90,
                                    positionFactor: 0.75,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // PM10 & AQI info vertically stacked
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "PM10: ${deviceData!['PM10']} µg/m³",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${_getAQILevel(deviceData!['PM10'], false)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AQIMeter(value: deviceData!['PM10']!, isPM2_5: false),
                    const LineGraph(isPM2_5: false),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: SfRadialGauge(
                            axes: <RadialAxis>[
                              RadialAxis(
                                minimum: 0,
                                maximum: 300,
                                ranges: <GaugeRange>[
                                  GaugeRange(
                                    startValue: 0,
                                    endValue: 50,
                                    color: Colors.lightGreen,
                                  ),
                                  GaugeRange(
                                    startValue: 50,
                                    endValue: 100,
                                    color: Colors.green,
                                  ),
                                  GaugeRange(
                                    startValue: 100,
                                    endValue: 150,
                                    color: Colors.yellow,
                                  ),
                                  GaugeRange(
                                    startValue: 150,
                                    endValue: 200,
                                    color: Colors.orange,
                                  ),
                                  GaugeRange(
                                    startValue: 200,
                                    endValue: 300,
                                    color: Colors.red,
                                  ),
                                ],
                                pointers: <GaugePointer>[
                                  NeedlePointer(
                                    value:
                                        calculateISPU(
                                          deviceData!['PM2.5'],
                                          true,
                                        ).toDouble(),
                                    needleColor: Colors.white,
                                    needleEndWidth: 3,
                                    knobStyle: const KnobStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                                annotations: <GaugeAnnotation>[
                                  GaugeAnnotation(
                                    widget: Text(
                                      'ISPU\n${calculateISPU(deviceData!['PM2.5'], true)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    angle: 90,
                                    positionFactor: 0.75,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "PM2.5: ${deviceData!['PM2.5']} µg/m³",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${_getAQILevel(deviceData!['PM2.5'], true)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AQIMeter(value: deviceData!['PM2.5']!, isPM2_5: true),
                    const LineGraph(isPM2_5: true),
                  ],
                )
                : Column(
                  children: [
                    Text(
                      "Loading Data...",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
          isConnected = false;
          FirebaseService().sendConnectionStatus(false);
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Device disconnected")));
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
          isConnected = false;
          FirebaseService().sendConnectionStatus(false);
        });
      }

      await Future.delayed(const Duration(seconds: 2));
      await BLEManager().tryReconnectFromPreferences();
      debugPrint("Reconnection triggered.");
    } catch (e) {
      debugPrint("Error during refresh: $e");
    }
  }

  int calculateISPU(double? x, bool isPM2_5) {
    // Define breakpoints for PM10 and PM2.5 in arrays of tuples:
    // Each tuple: [I_b, I_a, X_b, X_a]
    List<List<double>> breakpoints =
        isPM2_5
            ? [
              [0, 50, 0, 15.5],
              [51, 100, 15.5, 55.4],
              [101, 200, 55.4, 150.4],
              [201, 300, 150.4, 250.4],
              [301, 500, 250.4, 500],
            ]
            : [
              [0, 50, 0, 50],
              [51, 100, 50, 150],
              [101, 200, 150, 350],
              [201, 300, 350, 420],
              [301, 500, 420, 500],
            ];

    for (var bp in breakpoints) {
      double I_b = bp[0];
      double I_a = bp[1];
      double X_b = bp[2];
      double X_a = bp[3];

      if (x! >= X_b && x! <= X_a) {
        // Apply formula
        return (((I_a - I_b) / (X_a - X_b)) * (x - X_b) + I_b).round();
      }
    }
    // If outside max range, cap to 500
    return 500;
  }
}
