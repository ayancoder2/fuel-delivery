import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'screens/onboarding/splash_screen.dart';
import 'services/notification_service.dart';

void main() {
  // Bare minimum to get the engine running
  WidgetsFlutterBinding.ensureInitialized();
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
      // Use Bootstrap to handle the heavy lifting in the background
      home: const Bootstrap(),
    );
  }
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      debugPrint('BOOT_SEQ: [1] Starting background initialization...');
      
      // 1. Env
      await dotenv.load(fileName: ".env");
      debugPrint('BOOT_SEQ: [2] Dotenv loaded');

      // 2. Supabase
      await Supabase.initialize(
        url: dotenv.get('SUPABASE_URL'),
        anonKey: dotenv.get('SUPABASE_ANON_KEY'),
      );
      debugPrint('BOOT_SEQ: [3] Supabase ready');

      // 3. Notifications
      await NotificationService().init();
      debugPrint('BOOT_SEQ: [4] Notifications ready');

      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      debugPrint('BOOT_SEQ: [CRITICAL_ERROR] Bootstrap failed: $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to start app:\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      // Immediate UI while we wait
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E21),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6600)),
        ),
      );
    }

    // Success! Show the Splash Screen
    return const SplashScreen();
  }
}
