import 'package:cinefo_dubbing/splash/splashscreen.dart';
import 'package:flutter/material.dart';import 'Attendance/dailogei.dart';

import 'variables.dart'; // Import the file where routeObserver is defined
void main() {
  IntimeSyncService().startSync(); // Start background FIFO sync at app startup
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      home: SplashScreen(),
    );
  }
}
