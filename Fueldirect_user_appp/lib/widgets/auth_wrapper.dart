import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/onboarding/fuel_onboarding_screen.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Session? _session;
  bool _isLoading = true;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
    _subscribeToAuthChanges();
  }

  Future<void> _checkInitialSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      debugPrint('BOOT_SEQ: [13] AuthWrapper initial session check: ${session != null ? 'Logged In' : 'Logged Out'}');
      
      if (mounted) {
        setState(() {
          _session = session;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('BOOT_SEQ: [ERROR] AuthWrapper session check failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      debugPrint('BOOT_SEQ: [14] AuthWrapper state change: ${session != null ? 'Authenticated' : 'Unauthenticated'}');
      
      if (mounted) {
        setState(() {
          _session = session;
        });
        
        if (session != null) {
          _triggerWelcomeNotification();
        }
      }
    });
  }

  Future<void> _triggerWelcomeNotification() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Small delay to ensure DB is ready
      await Future.delayed(const Duration(seconds: 2));
      NotificationService.sendNotification(
        userId: user.id,
        title: 'Welcome to FuelDirect! 🚀',
        body: 'Your account is ready. Order fuel anytime, anywhere.',
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('BOOT_SEQ: [12] AuthWrapper build() triggered');

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6600)),
        ),
      );
    }

    final user = _session?.user;
    if (user != null) {
      return FutureBuilder<bool>(
        future: AuthService.isOTPPending(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6600)),
              ),
            );
          }
          
          if (snapshot.data == true) {
            return const LoginScreen();
          }
          
          debugPrint('BOOT_SEQ: [15] AuthWrapper navigating to DashboardScreen');
          return DashboardScreen();
        },
      );
    } else {
      // Check for Developer Bypass session
      return FutureBuilder<bool>(
        future: AuthService.isDevBypassActive(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
             debugPrint('BOOT_SEQ: [15] AuthWrapper (DevBypass) navigating to DashboardScreen');
             return DashboardScreen();
          }
          debugPrint('BOOT_SEQ: [15] AuthWrapper navigating to FuelOnboardingScreen');
          return const FuelOnboardingScreen();
        },
      );
    }
  }
}
