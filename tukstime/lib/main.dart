/// TuksTime: A Flutter application for time management
///
/// This file contains the main entry point of the application and defines the root widget.

import 'package:flutter/material.dart';
import 'package:tukstime/screens/weekly_screen.dart';

/// The main entry point for the TuksTime application.
void main() {
  runApp(const MyApp());
}

/// The root widget of the TuksTime application.
///
/// This widget sets up the MaterialApp and defines the initial route.
class MyApp extends StatelessWidget {
  /// Creates a new instance of MyApp.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuksTime',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WeeklyScreen(),
    );
  }
}
