import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPage = 0;
  String? connectedDeviceName;
  String? connectedDeviceId;

  @override
  void initState() {
    super.initState();
    _loadConnectedDevice();
  }

  Future<void> _loadConnectedDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceName = prefs.getString('connected_device_name');
    String? deviceId = prefs.getString(
      'connected_device_id',
    ); // Load the device ID

    setState(() {
      connectedDeviceName = deviceName ?? "No device connected";
      connectedDeviceId = deviceId ?? ""; // Ensure it's never null
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
                      ? _connectedDeviceList()
                      : Center(
                        child: Text(
                          "No connected devices",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: _devHeight * 0.03),
              width: _devWidth * 0.8,
              child: MaterialButton(
                onPressed: () {
                  Navigator.popAndPushNamed(context, 'find_device');
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded corners
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

  Widget _connectedDeviceList() {
    return ListView.builder(
      itemCount: connectedDeviceName != null ? 1 : 0, // Prevents ListView crash
      itemBuilder: (context, index) {
        return Card(
          color: Colors.black26,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(Icons.bluetooth, color: Colors.cyan),
            title: Text(
              connectedDeviceName!,
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              connectedDeviceId!.isNotEmpty
                  ? connectedDeviceId!
                  : "No ID available",
              style: TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _clearConnectedDevice,
            ),
          ),
        );
      },
    );
  }

  Future<void> _clearConnectedDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('connected_device_name');
    await prefs.remove('connected_device_id');

    setState(() {
      connectedDeviceName = null;
      connectedDeviceId = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Device disconnected")));
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
        BottomNavigationBarItem(label: "Search", icon: Icon(Icons.search)),
        BottomNavigationBarItem(
          label: "Profile",
          icon: Icon(Icons.account_box),
        ),
      ],
    );
  }
}
