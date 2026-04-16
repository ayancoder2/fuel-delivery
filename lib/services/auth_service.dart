import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => client.auth.currentSession != null;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final formattedPhone = formatPhone(phone);
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone_number': formattedPhone,
      },
    );
  }

  static Future<void> signOut() async {
    await setDevBypass(false); // Reset bypass on logout
    await client.auth.signOut();
  }

  static Future<void> sendOTP(String email) async {
    await client.auth.signInWithOtp(
      email: email,
    );
  }

  static Future<void> sendPhoneOTP(String phone) async {
    final formattedPhone = formatPhone(phone);
    await client.auth.signInWithOtp(
      phone: formattedPhone,
    );
  }

  static String formatPhone(String phone) {
    // Remove all non-numeric characters except '+'
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.startsWith('+')) return cleaned;

    // Detect Pakistan Format: 11 digits starting with '0'
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      return '+92${cleaned.substring(1)}';
    }
    
    // Detect US Format: 10 digits
    if (cleaned.length == 10) {
      return '+1$cleaned';
    }
    
    // Default fallback to US if not specified, or just prepend '+' if it looks like a code
    if (!cleaned.startsWith('+')) {
      return cleaned.length > 10 ? '+$cleaned' : '+1$cleaned';
    }
    
    return cleaned;
  }

  static Future<AuthResponse> verifyOTP({
    String? email,
    String? phone,
    required String token,
    required OtpType type,
  }) async {
    final formattedPhone = phone != null ? formatPhone(phone) : null;
    final response = await client.auth.verifyOTP(
      email: email,
      phone: formattedPhone,
      token: token,
      type: type,
    );
    // On success, clear the pending flag
    await setPendingOTP(false);
    return response;
  }

  // --- Auth State Helpers ---
  static const String _pendingOTPKey = 'is_otp_pending';
  static const String _devBypassKey = 'is_dev_bypass_active';

  static Future<void> setPendingOTP(bool pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingOTPKey, pending);
  }

  static Future<bool> isOTPPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pendingOTPKey) ?? false;
  }

  static Future<void> setDevBypass(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devBypassKey, active);
  }

  static Future<bool> isDevBypassActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_devBypassKey) ?? false;
  }
}
