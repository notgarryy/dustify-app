import 'package:dustify/pages/find_device_page.dart';
import 'package:dustify/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log the error to console
    debugPrint("Caught Flutter framework error:\n${details.exception}");
  };

  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (Object error, StackTrace stack) {
      // Catch errors that are not from Flutter framework (e.g., async stuff)
      debugPrint("Caught zone error: $error");
      debugPrint("Stack trace: $stack");
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final title = 'Dustify';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(useMaterial3: true),
      initialRoute: 'home',
      routes: {
        'home': (context) => HomePage(),
        'find_device': (context) => FindDevices(),
      },
    );
  }
}
