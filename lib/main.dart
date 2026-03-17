import 'package:flutter/material.dart';
import 'screens/onboarding/splash_screen.dart';

void main() {
  runApp(const FuelDirectApp());
}

class FuelDirectApp extends StatelessWidget {
  const FuelDirectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FuelDirect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
