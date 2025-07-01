import 'package:flutter/material.dart';
import 'package:dustify/services/firebase_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:dustify/services/ble_manager.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  double? devHeight;
  double? devWidth;
  bool? hasUser;

  FirebaseService? _firebaseService;

  bool _notificationsEnabled = true;
  bool _doNotDisturb = false;
  int _notificationInterval = 15; // in minutes

  @override
  void initState() {
    super.initState();
    _firebaseService = GetIt.instance.get<FirebaseService>();
    final loggedInUser = _firebaseService!.currentFirebaseUser;

    if (loggedInUser == null) {
      hasUser = false;
    } else {
      hasUser = true;
    }

    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _doNotDisturb = prefs.getBool('doNotDisturb') ?? false;
      _notificationInterval = prefs.getInt('notificationInterval') ?? 15;
    });
  }

  Future<void> _setNotificationPreference({
    bool? enableNotifications,
    bool? doNotDisturb,
    int? notificationInterval,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (enableNotifications != null) {
      await prefs.setBool('notificationsEnabled', enableNotifications);
    }
    if (doNotDisturb != null) {
      await prefs.setBool('doNotDisturb', doNotDisturb);
    }
    if (notificationInterval != null) {
      await prefs.setInt('notificationInterval', notificationInterval);
    }
  }

  @override
  Widget build(BuildContext context) {
    devHeight = MediaQuery.of(context).size.height;
    devWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(34, 31, 31, 1),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: devHeight! * 0.01),
                    _buildProfileCard(),
                    SizedBox(height: devHeight! * 0.02),
                    _notificationSettingsSection(),
                    SizedBox(height: devHeight! * 0.02),
                    _ISPUMeterInfoSection(),
                    SizedBox(height: devHeight! * 0.02),
                    _aboutSection(),
                  ],
                ),
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _ISPUMeterInfoSection() {
    final ISPUColors = [
      {
        'color': Colors.lightGreenAccent,
        'label': 'Very Good',
        'info': 'Air quality is excellent, safe for everyone.',
      },
      {
        'color': Colors.green,
        'label': 'Good',
        'info': 'Air quality is acceptable with minimal risk.',
      },
      {
        'color': Colors.yellow,
        'label': 'Fair',
        'info':
            'Moderate air quality; some pollutants may affect sensitive groups.',
      },
      {
        'color': Colors.orangeAccent,
        'label': 'Poor',
        'info':
            'Unhealthy for sensitive groups; consider limiting outdoor activity.',
      },
      {
        'color': Colors.red,
        'label': 'Hazardous',
        'info':
            'Health warnings of emergency conditions; avoid outdoor exposure.',
      },
    ];

    return Container(
      width: devWidth! * 0.90,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.speed, color: Colors.orange, size: 30),
                ),
                const SizedBox(width: 8),
                Text(
                  "ISPU Meter Info",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "The ISPU meter visually represents the air quality based on the following ranges and colors:",
            style: TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children:
                ISPUColors.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: entry['color'] as Color,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry['label'] as String,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            entry['info'] as String,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Center(
      child:
          hasUser!
              ? Container(
                height: devHeight! * 0.23,
                width: devWidth! * 0.90,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _profileImage(),
                    Container(
                      margin: EdgeInsets.only(bottom: 10),
                      child: Text(
                        "${_firebaseService!.currentUser!["name"]}",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    _logoutButton(),
                  ],
                ),
              )
              : Container(
                height: devHeight! * 0.2,
                width: devWidth! * 0.90,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [_profileImage(), _loginButton()],
                ),
              ),
    );
  }

  Widget _profileImage() {
    return Container(
      margin: EdgeInsets.only(
        top: devHeight! * 0.02,
        bottom: devHeight! * 0.015,
      ),
      height: devHeight! * 0.08,
      width: devHeight! * 0.08,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage('assets/images/blank_profile.png'),
        ),
      ),
    );
  }

  Widget _aboutSection() {
    return Container(
      width: devWidth! * 0.90,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black,
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "About",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "This app is developed to help you monitor and analyze PM2.5 and PM10 data from your BLE-connected Dustify device. Stay safe by keeping track of air quality trends wherever you go.",
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationSettingsSection() {
    return Container(
      width: devWidth! * 0.90,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  "Notification Settings",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _setNotificationPreference(enableNotifications: value);
            },
            title: const Text(
              'Enable push notifications',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            activeColor: Colors.orange,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _doNotDisturb,
            onChanged: (value) {
              setState(() => _doNotDisturb = value);
              final dataToSend = value ? [1] : [0];
              BLEManager().sendDataToDevice(Uint8List.fromList(dataToSend));
            },
            title: const Text(
              'Silent device alarm',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            activeColor: Colors.orange,
          ),
          const SizedBox(height: 16),
          Container(
            width: devWidth! * 0.8,
            child: Column(
              children: [
                Text(
                  "Notification Interval",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                DropdownButton<int>(
                  dropdownColor: Colors.black,
                  value: _notificationInterval,
                  isExpanded: true,
                  items:
                      [15, 30, 60, 120].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(
                            "$value minutes",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() => _notificationInterval = value!);
                    _setNotificationPreference(notificationInterval: value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginButton() {
    return MaterialButton(
      padding: EdgeInsets.only(top: 5, bottom: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      onPressed: () {
        Navigator.popAndPushNamed(context, 'login');
      },
      child: Text(
        "Log In >",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return MaterialButton(
      padding: EdgeInsets.only(top: 12, bottom: 12, left: 20, right: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      onPressed: () async {
        await _firebaseService!.logout();
        Navigator.popAndPushNamed(context, 'home');
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Log Out",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          SizedBox(width: devWidth! * 0.02),
          const Icon(color: Colors.white, Icons.logout),
        ],
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        "Dustify v0.2.1",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
