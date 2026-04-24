import 'package:flutter/material.dart';
import 'dart:async';
import '../../widgets/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('BOOT_SEQ: [9] SplashScreen initState()');
    
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        debugPrint('BOOT_SEQ: [1] SplashScreen timer fired, navigating to AuthWrapper');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('BOOT_SEQ: [10] SplashScreen build()');
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: const Text(
                'Get premium quality fuel delivered directly to your vehicle, wherever you are',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
