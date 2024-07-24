import 'package:flutter/material.dart';
import 'package:incubapp_lite/views/splashscreen.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Incuapp Lite',
      home: SplashScreen()
    );
  }
}
