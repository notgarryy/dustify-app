import 'package:dustify/pages/find_device_page.dart';
import 'package:dustify/pages/home_page.dart';
import 'package:dustify/pages/data_page.dart';
import 'package:dustify/pages/login_page.dart';
import 'package:dustify/services/firebase_manager.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      GetIt.instance.registerSingleton<FirebaseService>(FirebaseService());

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
      routes: {
        'home': (context) => HomePage(),
        'data': (context) => DataPage(),
        'find_device': (context) => FindDevices(),
        'login': (context) => LoginPage(),
      },
    );
  }
}
