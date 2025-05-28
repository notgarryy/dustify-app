import 'package:dustify/pages/find_device_page.dart';
import 'package:dustify/pages/history_page.dart';
import 'package:dustify/pages/home_page.dart';
import 'package:dustify/pages/data_page.dart';
import 'package:dustify/pages/login_page.dart';
import 'package:dustify/pages/profile_page.dart';
import 'package:dustify/pages/register_page.dart';
import 'package:dustify/services/firebase_manager.dart';
import 'package:dustify/services/ble_manager.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';

void main() {
  runZonedGuarded(
    () async {
      FirebaseService? _firebaseService;
      WidgetsFlutterBinding.ensureInitialized();

      await BLEManager().loadRecentData();
      await BLEManager().tryReconnectFromPreferences();

      await Firebase.initializeApp();
      _firebaseService = FirebaseService();
      GetIt.instance.registerSingleton<FirebaseService>(_firebaseService);

      await _firebaseService.checkAndLoadUserData();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint("Caught Flutter framework error:\n${details.exception}");
      };

      runApp(const MyApp());
    },
    (Object error, StackTrace stack) {
      debugPrint("Caught zone error: $error");
      debugPrint("Stack trace: $stack");
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dustify',
      theme: ThemeData(useMaterial3: true),
      initialRoute: 'home',
      debugShowCheckedModeBanner: false,
      routes: {
        'home': (context) => HomePage(),
        'data': (context) => DataPage(),
        'find_device': (context) => FindDevices(),
        'profile': (context) => ProfilePage(),
        'login': (context) => LoginPage(),
        'register': (context) => RegisterPage(),
        'history': (context) => HistoryPage(),
      },
    );
  }
}
