import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const IsusmApp());
}

class IsusmApp extends StatelessWidget {
  const IsusmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISU Soil Moisture App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
