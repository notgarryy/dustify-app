import 'package:dustify/pages/find_device_page.dart';
import 'package:dustify/pages/home_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
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
