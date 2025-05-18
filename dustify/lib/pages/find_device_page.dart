import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dustify/services/ble_manager.dart';

class FindDevices extends StatefulWidget {
  const FindDevices({super.key});

  @override
  State<FindDevices> createState() => _FindDevicesState();
}

class _FindDevicesState extends State<FindDevices> {
  List<BluetoothDevice> pairedDevices = [];
  bool isConnecting = false; // To track connection status

  @override
  void initState() {
    super.initState();
    _loadPairedDevices();
  }

  Future<void> _loadPairedDevices() async {
    try {
      List<BluetoothDevice> bonded = await FlutterBluePlus.bondedDevices;
      setState(() {
        // Optional: filter by name if only "Particulate Analyzer" devices are needed
        pairedDevices =
            bonded
                .where(
                  (device) =>
                      device.platformName.contains("Particulate Analyzer"),
                )
                .toList();
      });
    } catch (e) {
      debugPrint("Error loading paired devices: $e");
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true; // Start loading indicator
    });

    try {
      await BLEManager().connectToDevice(device);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('connected_device_id', device.remoteId.str);
      await prefs.setString('connected_device_name', device.platformName);

      if (mounted) {
        setState(() {
          isConnecting = false; // Stop loading indicator after connection
        });
        Navigator.pushReplacementNamed(context, 'home');
      }
    } catch (e) {
      setState(() {
        isConnecting = false; // Stop loading indicator on error
      });
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error connecting to device")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double devHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(34, 31, 31, 1),
      appBar: AppBar(
        title: Text(
          "Pair Device",
          style: TextStyle(fontFamily: 'BungeeSpice', fontSize: 40),
        ),
        backgroundColor: Color.fromRGBO(29, 28, 28, 1),
        centerTitle: true,
        toolbarHeight: devHeight * 0.08,
        leading: GestureDetector(
          onTap: () {
            Navigator.popAndPushNamed(context, 'home');
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body:
          isConnecting
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(
                      height: 10,
                    ), // Add some space between the spinner and text
                    Text(
                      "Connecting...",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              )
              : pairedDevices.isEmpty
              ? const Center(
                child: Text(
                  "No paired devices found.\nPlease pair via Bluetooth settings.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
              : ListView.builder(
                itemCount: pairedDevices.length,
                itemBuilder: (context, index) {
                  final device = pairedDevices[index];
                  return ListTile(
                    title: Text(
                      device.platformName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      device.remoteId.str,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.bluetooth_connected,
                      color: Colors.cyan,
                    ),
                    onTap: () => _connectToDevice(device),
                  );
                },
              ),
    );
  }
}
